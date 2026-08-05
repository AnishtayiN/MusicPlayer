import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'models/track.dart';
import 'theme/app_theme.dart';
import 'services/player_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'screens/player_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/mini_player.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final playerService = await AudioService.init(
    builder: () => PlayerService(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.sonic_wave.audio',
      androidNotificationChannelName: 'SonicWave',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(SonicWaveApp(
    playerService: playerService,
    storageService: storageService,
  ));
}

class SonicWaveApp extends StatefulWidget {
  final PlayerService playerService;
  final StorageService storageService;

  const SonicWaveApp({
    super.key,
    required this.playerService,
    required this.storageService,
  });

  @override
  State<SonicWaveApp> createState() => _SonicWaveAppState();
}

class _SonicWaveAppState extends State<SonicWaveApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.storageService.isDarkTheme();
    AppTheme.isDark = _isDark;
  }

  void _setTheme(bool dark) {
    setState(() {
      _isDark = dark;
      AppTheme.isDark = dark;
    });
    widget.storageService.setDarkTheme(dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SonicWave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        playerService: widget.playerService,
        storageService: widget.storageService,
        isDark: _isDark,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final PlayerService playerService;
  final StorageService storageService;
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const MainScreen({
    super.key,
    required this.playerService,
    required this.storageService,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final UpdateService _updateService = UpdateService();
  int _currentScreen = 0;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate({bool manual = false}) async {
    final update = await _updateService.checkForUpdate();
    if (!mounted) return;

    if (update == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('نسخه شما به‌روز است یا امکان بررسی وجود ندارد'),
            backgroundColor: AppTheme.surface,
          ),
        );
      }
      return;
    }

    if (!manual && widget.storageService.getSkipUpdate(update.version)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        updateInfo: update,
        updateService: _updateService,
        onSkip: () async {
          await widget.storageService.setSkipUpdate(update.version, true);
          if (mounted) Navigator.of(context).pop();
        },
        onLater: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _playTrack(Track track, List<Track> queue) async {
    await widget.playerService.loadTracks(queue);
    final index = queue.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      await widget.playerService.skipToQueueItem(index);
    }
    setState(() => _currentScreen = 0);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          isDark: widget.isDark,
          onThemeChanged: widget.onThemeChanged,
          onCheckUpdate: () => _checkForUpdate(manual: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: widget.playerService.mediaItem,
      builder: (context, snapshot) {
        final hasTrack = snapshot.data != null;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: IndexedStack(
            index: _currentScreen,
            children: [
              PlayerScreen(
                playerService: widget.playerService,
                storageService: widget.storageService,
                onOpenLibrary: () => setState(() => _currentScreen = 1),
                onOpenSettings: () => _openSettings(context),
              ),
              LibraryScreen(
                storageService: widget.storageService,
                currentTrackId: widget.playerService.currentTrack?.id,
                onPlayTrack: _playTrack,
                onOpenSettings: () => _openSettings(context),
              ),
            ],
          ),
          bottomNavigationBar: hasTrack && _currentScreen != 0
              ? StreamBuilder<PlaybackState>(
                  stream: widget.playerService.playbackState,
                  builder: (context, stateSnapshot) {
                    final playing = stateSnapshot.data?.playing ?? false;
                    return MiniPlayer(
                      currentTrack: widget.playerService.currentTrack,
                      isPlaying: playing,
                      onTap: () => setState(() => _currentScreen = 0),
                      onPlayPause: playing
                          ? widget.playerService.pause
                          : widget.playerService.play,
                      onNext: widget.playerService.skipToNext,
                      onClose: () => widget.playerService.stopAndClear(),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
