import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'models/track.dart';
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

class SonicWaveApp extends StatelessWidget {
  final PlayerService playerService;
  final StorageService storageService;

  const SonicWaveApp({
    super.key,
    required this.playerService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SonicWave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070B14),
      ),
      home: MainScreen(
        playerService: playerService,
        storageService: storageService,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final PlayerService playerService;
  final StorageService storageService;

  const MainScreen({
    super.key,
    required this.playerService,
    required this.storageService,
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

  Future<void> _checkForUpdate() async {
    final update = await _updateService.checkForUpdate();
    if (update == null || !mounted) return;
    if (widget.storageService.getSkipUpdate(update.version)) return;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: widget.playerService.mediaItem,
      builder: (context, snapshot) {
        final hasTrack = snapshot.data != null;

        return Scaffold(
          backgroundColor: const Color(0xFF070B14),
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
                    );
                  },
                )
              : null,
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}
