import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';
import '../services/player_service.dart';
import '../services/storage_service.dart';

class PlayerScreen extends StatefulWidget {
  final PlayerService playerService;
  final StorageService storageService;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenSettings;

  const PlayerScreen({
    super.key,
    required this.playerService,
    required this.storageService,
    required this.onOpenLibrary,
    required this.onOpenSettings,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _discController;
  Color _dominantColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    widget.playerService.playbackState.listen((state) {
      if (state.playing) {
        if (!_discController.isAnimating) _discController.repeat();
      } else {
        if (_discController.isAnimating) _discController.stop();
      }
    });

    widget.playerService.mediaItem.listen((item) {
      if (item?.artUri != null) {
        _updatePalette(item!.artUri!);
      }
    });
  }

  Future<void> _updatePalette(Uri uri) async {
    try {
      final generator =
          await PaletteGenerator.fromImageProvider(NetworkImage(uri.toString()));

      if (mounted) {
        setState(() {
          _dominantColor =
              generator.dominantColor?.color ?? const Color(0xFF8B5CF6);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _discController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: widget.playerService.mediaItem,
      builder: (context, mediaSnapshot) {
        final currentTrack = widget.playerService.currentTrack;

        if (currentTrack == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent2],
                      ),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SonicWave',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'از کتابخانه یک آهنگ انتخاب کن',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenLibrary,
                    icon: const Icon(Icons.library_music),
                    label: const Text('رفتن به کتابخانه'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _dominantColor.withOpacity(AppTheme.isDark ? 0.35 : 0.18),
                  AppTheme.background,
                  AppTheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(currentTrack),
                  Expanded(flex: 4, child: _buildDisc(currentTrack)),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPlayerControls(currentTrack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Track track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onOpenLibrary,
            icon: Icon(Icons.keyboard_arrow_down,
                color: AppTheme.iconActive, size: 32),
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              await widget.storageService.toggleFavorite(track);
              setState(() {});
            },
            icon: Icon(
              widget.storageService.isFavorite(track.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: widget.storageService.isFavorite(track.id)
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: widget.onOpenSettings,
            icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDisc(Track track) {
    return Center(
      child: RotationTransition(
        turns: _discController,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _dominantColor,
                _dominantColor.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _dominantColor.withOpacity(0.4),
                blurRadius: 60,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  track.artworkUrl != null
                      ? Image.network(
                          track.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surface,
                            child: Center(
                              child: Icon(Icons.music_note_rounded,
                                  size: 64, color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surface,
                          child: Center(
                            child: Icon(Icons.music_note_rounded,
                                size: 64, color: AppTheme.textMuted),
                          ),
                        ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.cardBorder,
                          width: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls(Track track) {
    return StreamBuilder<Duration>(
      stream: widget.playerService.player.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration?>(
          stream: widget.playerService.player.durationStream,
          builder: (context, durSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final duration = durSnapshot.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds.toDouble();
            final currentMs = position.inMilliseconds.toDouble();
            final sliderMax = maxMs <= 0 ? 1.0 : maxMs;
            final sliderValue = currentMs.clamp(0.0, sliderMax).toDouble();

            return StreamBuilder<PlaybackState>(
              stream: widget.playerService.playbackState,
              builder: (context, stateSnapshot) {
                final playing = stateSnapshot.data?.playing ?? false;
                final buffering = stateSnapshot.data?.processingState ==
                    AudioProcessingState.buffering;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.artist,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Slider(
                      value: sliderValue,
                      min: 0,
                      max: sliderMax,
                      activeColor: _dominantColor,
                      inactiveColor: AppTheme.sliderInactive,
                      thumbColor: AppTheme.iconActive,
                      onChanged: (value) {
                        widget.playerService
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildControlButtons(playing, buffering),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons(bool playing, bool buffering) {
    final loopIcon = widget.playerService.loopMode == LoopMode.one
        ? Icons.repeat_one
        : Icons.repeat;
    final loopActive = widget.playerService.loopMode != LoopMode.off;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: widget.playerService.cycleLoop,
          icon: Icon(loopIcon,
              color: loopActive ? AppTheme.iconActive : AppTheme.iconInactive),
        ),
        IconButton(
          onPressed: widget.playerService.skipToPrevious,
          icon: Icon(Icons.skip_previous,
              size: 44, color: AppTheme.iconActive),
        ),
        GestureDetector(
          onTap: playing
              ? widget.playerService.pause
              : widget.playerService.play,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _dominantColor,
                  _dominantColor.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _dominantColor.withOpacity(0.45),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Center(
              child: buffering
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.playerService.skipToNext,
          icon:
              Icon(Icons.skip_next, size: 44, color: AppTheme.iconActive),
        ),
        IconButton(
          onPressed: widget.playerService.toggleShuffle,
          icon: Icon(
            Icons.shuffle,
            color: widget.playerService.shuffleEnabled
                ? AppTheme.iconActive
                : AppTheme.iconInactive,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }
}
