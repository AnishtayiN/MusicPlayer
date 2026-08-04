import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class PlayerService extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  List<Track> _tracks = [];
  int _currentIndex = 0;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<int?>? _indexSub;

  PlayerService() {
    _init();
  }

  Future<void> _init() async {
    _positionSub = _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });

    _stateSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        processingState: _mapProcessingState(processingState),
      ));
    });

    _indexSub = _player.currentIndexStream.listen((index) {
      if (index != null && index < _tracks.length) {
        _currentIndex = index;
        mediaItem.add(_tracksToMediaItem(_tracks[index]));
      }
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  MediaItem _tracksToMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: track.artworkUrl != null ? Uri.tryParse(track.artworkUrl!) : null,
      duration: Duration(milliseconds: track.durationMs ?? 0),
    );
  }

  Future<void> loadTracks(List<Track> tracks) async {
    _tracks = tracks;

    final audioSources = tracks.map((track) {
      if (track.isLocal && track.localPath != null) {
        return AudioSource.file(track.localPath!);
      } else {
        return AudioSource.uri(Uri.parse(track.url));
      }
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: 0,
      initialPosition: Duration.zero,
    );

    queue.add(tracks.map(_tracksToMediaItem).toList());
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_tracks.isEmpty) return;

    final nextIndex = _nextIndex();
    await _player.seek(Duration.zero, index: nextIndex);
    await play();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_tracks.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevIndex = _previousIndex();
    await _player.seek(Duration.zero, index: prevIndex);
    await play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _tracks.length) return;

    await _player.seek(Duration.zero, index: index);
    await play();
  }

  int _nextIndex() {
    if (_tracks.length <= 1) return _currentIndex;

    if (_shuffle) {
      int index;
      do {
        index = _random.nextInt(_tracks.length);
      } while (index == _currentIndex);
      return index;
    }

    return (_currentIndex + 1) % _tracks.length;
  }

  int _previousIndex() {
    if (_tracks.length <= 1) return _currentIndex;
    return (_currentIndex - 1 + _tracks.length) % _tracks.length;
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    await _player.setShuffleModeEnabled(_shuffle);
  }

  Future<void> cycleLoop() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }

    await _player.setLoopMode(_loopMode);
  }

  bool get shuffleEnabled => _shuffle;
  LoopMode get loopMode => _loopMode;
  int get currentIndex => _currentIndex;
  Track? get currentTrack => _currentIndex < _tracks.length ? _tracks[_currentIndex] : null;
  AudioPlayer get player => _player;

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _indexSub?.cancel();
    _player.dispose();
  }
}
