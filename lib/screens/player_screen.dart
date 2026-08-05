import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';
import '../services/player_service.dart';
import '../services/storage_service.dart';
import '../services/extra_services.dart';

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
    with TickerProviderStateMixin {
  late final AnimationController _disc;
  late final AnimationController _vis;
  Color _dominant = const Color(0xFF8B5CF6);

  TrackMeta? _meta;
  LyricsResult? _lyrics;
  bool _showLyrics = false;
  bool _loadingLyrics = false;
  final ScrollController _lyricScroll = ScrollController();
  int _lyricIndex = -1;

  Timer? _sleepTimer;
  int _sleepSec = 0;

  @override
  void initState() {
    super.initState();
    _disc = AnimationController(vsync: this, duration: const Duration(seconds: 14));
    _vis = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    widget.playerService.playbackState.listen((s) {
      if (s.playing) {
        if (!_disc.isAnimating) _disc.repeat();
        if (!_vis.isAnimating) _vis.repeat();
      } else {
        _disc.stop();
        _vis.stop();
      }
    });

    widget.playerService.mediaItem.listen((m) {
      if (m != null) _onTrackChanged();
    });
  }

  void _onTrackChanged() {
    final t = widget.playerService.currentTrack;
    if (t == null) return;
    _meta = null;
    _lyrics = null;
    _lyricIndex = -1;
    if (t.artworkUrl != null) {
      PaletteGenerator.fromImageProvider(NetworkImage(t.artworkUrl!))
          .then((g) {
        if (mounted) {
          setState(() => _dominant =
              g.dominantColor?.color ?? const Color(0xFF8B5CF6));
        }
      }).catchError((_) {});
    }
    fetchMetadata(t).then((m) {
      if (mounted && m != null) setState(() => _meta = m);
    });
    if (_showLyrics) _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final t = widget.playerService.currentTrack;
    if (t == null) return;
    setState(() => _loadingLyrics = true);
    final saved = widget.storageService.getSavedLyrics(t.id);
    final r = await loadLyrics(t, saved);
    if (mounted) {
      setState(() {
        _lyrics = r;
        _loadingLyrics = false;
      });
    }
  }

  Future<void> _pasteLyrics() async {
    final t = widget.playerService.currentTrack;
    if (t == null) return;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('افزودن متن آهنگ',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: c,
            maxLines: 10,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'متن را اینجا paste کنید (LRC یا ساده)',
              hintStyle: TextStyle(color: AppTheme.textFaint),
              filled: true,
              fillColor: AppTheme.surfaceSoft,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('انصراف',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white),
              child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await widget.storageService.setSavedLyrics(t.id, c.text);
      _loadLyrics();
    }
  }

  void _startSleep(int minutes) {
    _sleepTimer?.cancel();
    if (minutes == 0) {
      setState(() => _sleepSec = 0);
      return;
    }
    setState(() => _sleepSec = minutes * 60);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (tm) async {
      _sleepSec--;
      if (_sleepSec <= 10 && _sleepSec > 0) {
        await widget.playerService.setVolume(_sleepSec / 10);
      }
      if (_sleepSec <= 0) {
        tm.cancel();
        await widget.playerService.pause();
        await widget.playerService.setVolume(
            widget.storageService.getVolume());
      }
      if (mounted) setState(() {});
    });
  }

  bool _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final k = e.logicalKey;
    final ps = widget.playerService;
    if (k == LogicalKeyboardKey.space) {
      ps.playing ? ps.pause() : ps.play();
      return true;
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      if (k == LogicalKeyboardKey.arrowRight) { ps.skipToNext(); return true; }
      if (k == LogicalKeyboardKey.arrowLeft) { ps.skipToPrevious(); return true; }
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      ps.setVolume(ps.volume + 0.05);
      setState(() {});
      return true;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      ps.setVolume(ps.volume - 0.05);
      setState(() {});
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _disc.dispose();
    _vis.dispose();
    _lyricScroll.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  Widget _cover(Track t, double size) {
    Widget inner;
    if (_meta?.coverDataUrl != null) {
      final parts = _meta!.coverDataUrl!.split(',');
      inner = Image.memory(base64Decode(parts.last), fit: BoxFit.cover);
    } else if (t.artworkId != null && !kIsWeb) {
      inner = ArtworkWidget(
        key: Key('big_${t.artworkId}'),
        type: ArtworkType.AUDIO,
        id: t.artworkId!,
        size: size.toInt(),
        errorWidget: Icon(Icons.music_note_rounded,
            size: size / 4, color: AppTheme.textMuted),
      );
    } else if (t.artworkUrl != null) {
      inner = Image.network(t.artworkUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.music_note_rounded,
              size: size / 4, color: AppTheme.textMuted));
    } else {
      inner = Icon(Icons.music_note_rounded,
          size: size / 4, color: AppTheme.textMuted);
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: inner));
  }

  Widget _visualizer() {
    return AnimatedBuilder(
      animation: _vis,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final h = 6 +
                14 *
                    (0.5 +
                        0.5 *
                            sin((_vis.value * 2 * pi) + i * 1.3));
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              color: _dominant,
            );
          }),
        );
      },
    );
  }

  Widget _lyricsPanel() {
    if (_loadingLyrics) {
      return Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_lyrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('متنی یافت نشد',
                style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pasteLyrics,
              child: Text('افزودن متن',
                  style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
      );
    }
    if (!_lyrics!.isSynced) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(_lyrics!.plain,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.8)),
      );
    }
    return StreamBuilder<Duration>(
      stream: widget.playerService.player.positionStream,
      builder: (ctx, snap) {
        final pos = snap.data ?? Duration.zero;
        final lines = _lyrics!.synced;
        int idx = -1;
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].time <= pos) idx = i; else break;
        }
        if (idx != _lyricIndex) {
          _lyricIndex = idx;
          if (idx >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_lyricScroll.hasClients) {
                _lyricScroll.animateTo(
                    (idx * 44.0) - 120,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
              }
            });
          }
        }
        return ListView.builder(
          controller: _lyricScroll,
          padding: const EdgeInsets.all(16),
          itemCount: lines.length,
          itemBuilder: (_, i) => Container(
            height: 44,
            alignment: Alignment.center,
            child: Text(
              lines[i].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: i == idx ? _dominant : AppTheme.textMuted,
                fontSize: i == idx ? 17 : 14,
                fontWeight: i == idx ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _queuePanel(bool sheet) {
    return StreamBuilder<List<MediaItem>>(
      stream: widget.playerService.queue,
      builder: (ctx, snap) {
        final tracks = widget.playerService.tracks;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('صف پخش (${tracks.length})',
                      style: TextStyle(color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (sheet)
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (_, i) {
                  final t = tracks[i];
                  final cur = i == widget.playerService.currentIndex;
                  return ListTile(
                    dense: true,
                    leading: Text('${i + 1}',
                        style: TextStyle(color: cur
                            ? AppTheme.accent : AppTheme.textFaint)),
                    title: Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: cur
                                ? AppTheme.accent : AppTheme.textPrimary,
                            fontWeight: cur ? FontWeight.w700 : FontWeight.w400)),
                    subtitle: Text(t.artist,
                        maxLines: 1,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    trailing: cur
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close, size: 16,
                                color: AppTheme.textFaint),
                            onPressed: () =>
                                widget.playerService.removeFromQueue(i)),
                    onTap: () {
                      widget.playerService.skipToQueueItem(i);
                      if (sheet) Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SizedBox(height: 420, child: _queuePanel(true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: StreamBuilder<MediaItem?>(
        stream: widget.playerService.mediaItem,
        builder: (context, snap) {
          final t = widget.playerService.currentTrack;

          if (t == null) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent2]),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text('SonicWave',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('از کتابخانه یک آهنگ انتخاب کن',
                        style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: widget.onOpenLibrary,
                      icon: const Icon(Icons.library_music),
                      label: const Text('رفتن به کتابخانه'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(builder: (ctx, cons) {
            final wide = cons.maxWidth >= 760;
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _dominant.withOpacity(AppTheme.isDark ? 0.30 : 0.15),
                      AppTheme.background,
                      AppTheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _header(t),
                            if (!_showLyrics) ...[
                              Expanded(
                                flex: 4,
                                child: Center(
                                  child: RotationTransition(
                                    turns: _disc,
                                    child: Container(
                                      width: 210, height: 210,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: [
                                          _dominant,
                                          _dominant.withOpacity(0.4)
                                        ]),
                                        boxShadow: [
                                          BoxShadow(
                                              color: _dominant.withOpacity(0.4),
                                              blurRadius: 50, spreadRadius: 2),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _cover(t, 194),
                                            Center(
                                              child: Container(
                                                width: 44, height: 44,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.background,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: AppTheme.cardBorder,
                                                      width: 5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              Expanded(flex: 4, child: _lyricsPanel()),
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _controls(t),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (wide)
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSoft,
                            border: Border(
                                left: BorderSide(color: AppTheme.cardBorder)),
                          ),
                          child: _queuePanel(false),
                        ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _header(Track t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onOpenLibrary,
            icon: Icon(Icons.keyboard_arrow_down,
                color: AppTheme.iconActive, size: 30),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() => _showLyrics = !_showLyrics);
              if (_showLyrics && _lyrics == null) _loadLyrics();
            },
            icon: Icon(
              Icons.lyrics_outlined,
              color: _showLyrics ? AppTheme.accent : AppTheme.textSecondary,
            ),
            tooltip: 'متن آهنگ',
          ),
          IconButton(
            onPressed: () async {
              await widget.storageService.toggleFavorite(t);
              setState(() {});
            },
            icon: Icon(
              widget.storageService.isFavorite(t.id)
                  ? Icons.favorite : Icons.favorite_border,
              color: widget.storageService.isFavorite(t.id)
                  ? AppTheme.accent : AppTheme.textSecondary,
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

  Widget _controls(Track t) {
    final ps = widget.playerService;
    return StreamBuilder<Duration>(
      stream: ps.player.positionStream,
      builder: (ctx, posSnap) {
        return StreamBuilder<Duration?>(
          stream: ps.player.durationStream,
          builder: (ctx, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final maxMs = dur.inMilliseconds.toDouble();
            final sliderMax = maxMs <= 0 ? 1.0 : maxMs;
            final val = pos.inMilliseconds.toDouble().clamp(0.0, sliderMax).toDouble();

            return StreamBuilder<PlaybackState>(
              stream: ps.playbackState,
              builder: (ctx, stSnap) {
                final playing = stSnap.data?.playing ?? false;
                final buffering = stSnap.data?.processingState ==
                    AudioProcessingState.buffering;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _visualizer(),
                    const SizedBox(height: 6),
                    Text(t.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        t.artist,
                        if (_meta?.album != null) _meta!.album!,
                        if (_meta?.year != null) '${_meta!.year}',
                        if (_meta?.bitrateKbps != null)
                          '${_meta!.bitrateKbps}kbps',
                      ].join(' • '),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: val, min: 0, max: sliderMax,
                      activeColor: _dominant,
                      inactiveColor: AppTheme.sliderInactive,
                      thumbColor: AppTheme.iconActive,
                      onChanged: (v) =>
                          ps.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(pos), style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                          if (_sleepSec > 0)
                            Text('⏰ ${_sleepSec ~/ 60}:${(_sleepSec % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    color: AppTheme.accent, fontSize: 11)),
                          Text(_fmt(dur), style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buttons(playing, buffering),
                    const SizedBox(height: 8),
                    _bottomRow(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buttons(bool playing, bool buffering) {
    final ps = widget.playerService;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => ps.cycleLoop().then((_) => setState(() {})),
          icon: Icon(
            ps.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
            color: ps.loopMode != LoopMode.off
                ? AppTheme.iconActive : AppTheme.iconInactive),
        ),
        IconButton(
          onPressed: ps.skipToPrevious,
          icon: Icon(Icons.skip_previous, size: 40, color: AppTheme.iconActive),
        ),
        GestureDetector(
          onTap: playing ? ps.pause : ps.play,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [_dominant, _dominant.withOpacity(0.6)]),
              boxShadow: [
                BoxShadow(color: _dominant.withOpacity(0.45), blurRadius: 22),
              ],
            ),
            child: Center(
              child: buffering
                  ? const SizedBox(width: 26, height: 26,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 40, color: Colors.white),
            ),
          ),
        ),
        IconButton(
          onPressed: ps.skipToNext,
          icon: Icon(Icons.skip_next, size: 40, color: AppTheme.iconActive),
        ),
        IconButton(
          onPressed: () => ps.toggleShuffle().then((_) => setState(() {})),
          icon: Icon(Icons.shuffle,
              color: ps.shuffleEnabled
                  ? AppTheme.iconActive : AppTheme.iconInactive),
        ),
      ],
    );
  }

  Widget _bottomRow() {
    final ps = widget.playerService;
    return Row(
      children: [
        IconButton(
          onPressed: () {
            ps.toggleMute();
            setState(() {});
          },
          icon: Icon(
            ps.volume == 0 ? Icons.volume_off : Icons.volume_down,
            color: AppTheme.textSecondary, size: 20),
        ),
        Expanded(
          child: Slider(
            value: ps.volume, min: 0, max: 1,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.sliderInactive,
            onChanged: (v) {
              ps.setVolume(v);
              setState(() {});
            },
          ),
        ),
        PopupMenuButton<double>(
          padding: EdgeInsets.zero,
          color: AppTheme.surface,
          onSelected: (s) {
            ps.setSpeed(s);
            setState(() {});
          },
          itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map((s) => PopupMenuItem(
                    value: s,
                    child: Text('${s}x',
                        style: TextStyle(
                            color: ps.speed == s
                                ? AppTheme.accent : AppTheme.textPrimary)),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${ps.speed}x',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ),
        PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          color: AppTheme.surface,
          onSelected: _startSleep,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 0, child: Text('خاموش', style: TextStyle(color: AppTheme.textPrimary))),
            ...[5, 15, 30, 60].map((m) => PopupMenuItem(
                value: m,
                child: Text('$m دقیقه', style: TextStyle(color: AppTheme.textPrimary)))),
          ],
          child: Icon(Icons.bedtime_outlined,
              color: _sleepSec > 0 ? AppTheme.accent : AppTheme.textSecondary,
              size: 20),
        ),
        IconButton(
          onPressed: _openQueueSheet,
          icon: Icon(Icons.queue_music, color: AppTheme.textSecondary, size: 20),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
