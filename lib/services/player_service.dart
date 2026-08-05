import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import 'storage_service.dart';

class PlayerService extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  final StorageService? storage;

  List<Track> _tracks = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;
  final Set<int> _played = {};
  final List<int> _history = [];

  double _volume = 1.0;
  double _savedVolume = 1.0;
  double _speed = 1.0;
  int _lastSavedSec = -1;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  PlayerService(this.storage) {
    _volume = storage?.getVolume() ?? 1.0;
    _speed = storage?.getSpeed() ?? 1.0;
    _init();
  }

  void _init() {
    _posSub = _player.positionStream.listen((p) {
      playbackState.add(playbackState.value.copyWith(updatePosition: p));
      final s = p.inSeconds;
      if (s != _lastSavedSec && s % 5 == 0 && currentTrack != null) {
        _lastSavedSec = s;
        storage?.setLastSession(currentTrack!.id, p.inMilliseconds);
      }
    });

    _stateSub = _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        processingState: _map(state.processingState),
      ));
      if (state.processingState == ProcessingState.completed) {
        _handleComplete();
      }
    });
  }

  AudioProcessingState _map(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  MediaItem _toMediaItem(Track t) => MediaItem(
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.album,
        artUri: t.artworkUrl != null ? Uri.tryParse(t.artworkUrl!) : null,
        duration: Duration(milliseconds: t.durationMs ?? 0),
      );


  Future<void> loadTracks(List<Track> tracks,
      {int startIndex = 0, bool autoplay = true}) async {
    _tracks = List.of(tracks);
    _played.clear();
    _history.clear();
    queue.add(_tracks.map(_toMediaItem).toList());
    if (_tracks.isEmpty) return;
    await _loadIndex(startIndex.clamp(0, _tracks.length - 1),
        autoplay: autoplay, recordHistory: false);
  }

  Future<void> addTracks(List<Track> added) async {
    if (_tracks.isEmpty) {
      await loadTracks(added);
      return;
    }
    _tracks.addAll(added);
    queue.add(_tracks.map(_toMediaItem).toList());
    if (!playing) await _loadIndex(_tracks.length - added.length);
  }

  Future<void> _loadIndex(int i,
      {bool autoplay = true, bool recordHistory = true}) async {
    if (_tracks.isEmpty || i < 0 || i >= _tracks.length) return;
    if (recordHistory && _currentIndex >= 0 && _currentIndex != i) {
      _history.add(_currentIndex);
    }
    _currentIndex = i;
    _played.add(i);
    final t = _tracks[i];
    try {
      if (t.isLocal && t.localPath != null && !kIsWeb) {
        await _player.setFilePath(t.localPath!);
      } else {
        await _player.setUrl(t.url);
      }
      await _player.setVolume(_volume);
      await _player.setSpeed(_speed);
      mediaItem.add(_toMediaItem(t));
      storage?.addHistory(t);
      storage?.setLastSession(t.id, 0);
      if (autoplay) await _player.play();
    } catch (_) {}
  }


  int _nextIndex({bool auto = false}) {
    final n = _tracks.length;
    if (n == 0) return -1;
    if (_loopMode == LoopMode.one) return _currentIndex;

    if (_shuffle) {
      if (n == 1) {
        if (_loopMode == LoopMode.all) return 0;
        return auto ? -1 : 0;
      }
      var remaining = [
        for (var i = 0; i < n; i++)
          if (!_played.contains(i) && i != _currentIndex) i
      ];
      if (remaining.isEmpty) {
        if (_loopMode == LoopMode.all) {
          _played.clear();
          _played.add(_currentIndex);
          remaining = [for (var i = 0; i < n; i++) if (i != _currentIndex) i];
        } else if (auto) {
          return -1;
        } else {
          _played.clear();
          _played.add(_currentIndex);
          remaining = [for (var i = 0; i < n; i++) if (i != _currentIndex) i];
        }
      }
      return remaining[_random.nextInt(remaining.length)];
    }

    final next = _currentIndex + 1;
    if (next >= n) {
      if (_loopMode == LoopMode.all) return 0;
      return auto ? -1 : 0;
    }
    return next;
  }

  void _handleComplete() {
    if (_loopMode == LoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }
    final idx = _nextIndex(auto: true);
    if (idx == -1) return;
    _loadIndex(idx);
  }


  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final idx = _nextIndex();
    if (idx == -1) return;
    await _loadIndex(idx);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_history.isNotEmpty) {
      await _loadIndex(_history.removeLast(), recordHistory: false);
    } else if (_currentIndex > 0) {
      await _loadIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async => _loadIndex(index);

  Future<void> removeFromQueue(int index) async {
    if (index == _currentIndex || index < 0 || index >= _tracks.length) return;
    _tracks.removeAt(index);
    if (_currentIndex > index) _currentIndex--;
    _played.clear();
    _history.clear();
    queue.add(_tracks.map(_toMediaItem).toList());
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    _played.clear();
  }

  Future<void> cycleLoop() async {
    switch (_loopMode) {
      case LoopMode.off: _loopMode = LoopMode.all; break;
      case LoopMode.all: _loopMode = LoopMode.one; break;
      case LoopMode.one: _loopMode = LoopMode.off; break;
    }
  }


  double get volume => _volume;

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    storage?.setVolume(_volume);
  }

  Future<void> toggleMute() async {
    if (_volume > 0) {
      _savedVolume = _volume;
      await setVolume(0);
    } else {
      await setVolume(_savedVolume > 0 ? _savedVolume : 1.0);
    }
  }

  double get speed => _speed;

  Future<void> setSpeed(double s) async {
    _speed = s;
    await _player.setSpeed(s);
    storage?.setSpeed(s);
  }

  Future<void> stopAndClear() async {
    await _player.stop();
    _tracks = [];
    _currentIndex = -1;
    _played.clear();
    _history.clear();
    mediaItem.add(null);
    queue.add(const []);
  }


  List<Track> get tracks => _tracks;
  int get currentIndex => _currentIndex;
  bool get shuffleEnabled => _shuffle;
  LoopMode get loopMode => _loopMode;
  bool get playing => _player.playing;
  AudioPlayer get player => _player;
  Track? get currentTrack =>
      _tracks.isNotEmpty && _currentIndex >= 0 && _currentIndex < _tracks.length
          ? _tracks[_currentIndex]
          : null;

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
  }
}
