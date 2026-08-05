import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../utils/web_bridge.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  final PlayerCallback onPlayTrack;
  final StorageService storageService;
  final String? currentTrackId;
  final VoidCallback onOpenSettings;

  const LibraryScreen({
    super.key,
    required this.onPlayTrack,
    required this.storageService,
    this.currentTrackId,
    required this.onOpenSettings,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

typedef PlayerCallback = void Function(Track track, List<Track> queue);

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final TextEditingController _searchController = TextEditingController();

  List<Track> _allTracks = [];
  List<Track> _filteredTracks = [];
  String _currentTab = 'all';
  bool _loading = true;
  String? _error;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = ['all', 'favorites', 'local'][_tabController.index];
          _applyFilter();
        });
      }
    });
    _loadTracks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _baseName(String p) {
    final norm = p.replaceAll('\\', '/');
    final name = norm.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  Future<void> _pickCustomFolder() async {
    try {
      String? path;

      if (kIsWeb) {
        if (!isElectronBridgeAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('انتخاب پوشه فقط در نسخه دسکتاپ فعال است'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
        path = await selectFolderNative();
      } else {
        path = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'پوشه موزیک خود را انتخاب کنید',
        );
      }

      if (path != null && path.isNotEmpty) {
        await widget.storageService.setCustomFolderPath(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('پوشه انتخاب شد: $path'),
              backgroundColor: AppTheme.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadTracks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در انتخاب پوشه: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _clearCustomFolder() async {
    await widget.storageService.setCustomFolderPath(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('پوشه انتخابی حذف شد، اسکن خودکار فعال است'),
          backgroundColor: AppTheme.surface,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _loadTracks();
  }

  Future<List<Track>> _scanFolder(String path) async {
    final List<Track> tracks = [];
    final extensions = {'.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'};

    try {
      final dir = Directory(path);
      if (!await dir.exists()) return tracks;

      final entities =
          await dir.list(recursive: true, followLinks: false).toList();

      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (extensions.any((e) => ext.endsWith(e))) {
            tracks.add(Track(
              id: 'folder_${entity.path.hashCode}',
              title: _baseName(entity.path),
              artist: 'Local File',
              url: entity.path,
              isLocal: true,
              localPath: entity.path,
              durationMs: null,
            ));
          }
        }
      }

      tracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (e) {
      // Scan failed
    }

    return tracks;
  }

  Future<List<Track>> _scanFolderWeb(String path) async {
    final files = await listAudioFilesNative(path);

    final tracks = files
        .map((p) => Track(
              id: 'folder_${p.hashCode}',
              title: _baseName(p),
              artist: 'Local File',
              url: localFileUrl(p),
              isLocal: true,
              localPath: null,
              durationMs: null,
            ))
        .toList();

    tracks.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return tracks;
  }

  Future<void> _loadTracks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final demoTracks = <Track>[
        Track(
          id: 'demo_1',
          title: 'Neon Drive',
          artist: 'SoundHelix',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          artworkUrl: 'https://picsum.photos/seed/neon/700/700',
          durationMs: 372000,
        ),
        Track(
          id: 'demo_2',
          title: 'Midnight Pulse',
          artist: 'SoundHelix',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          artworkUrl: 'https://picsum.photos/seed/midnight/700/700',
          durationMs: 420000,
        ),
        Track(
          id: 'demo_3',
          title: 'Cyber Sunset',
          artist: 'SoundHelix',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          artworkUrl: 'https://picsum.photos/seed/cyber/700/700',
          durationMs: 395000,
        ),
        Track(
          id: 'demo_4',
          title: 'Aurora Bass',
          artist: 'SoundHelix',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          artworkUrl: 'https://picsum.photos/seed/aurora/700/700',
          durationMs: 360000,
        ),
      ];

      List<Track> localTracks = [];
      final customPath = widget.storageService.getCustomFolderPath();

      if (customPath != null && customPath.isNotEmpty) {
        if (kIsWeb) {
          localTracks = await _scanFolderWeb(customPath);
        } else {
          localTracks = await _scanFolder(customPath);
        }
      } else if (!kIsWeb) {
        try {
          final status = await Permission.audio.status;
          PermissionStatus finalStatus = status;

          if (!status.isGranted) {
            finalStatus = await Permission.audio.request();
          }

          if (!finalStatus.isGranted) {
            finalStatus = await Permission.storage.request();
          }

          if (finalStatus.isGranted) {
            final songs = await _audioQuery.querySongs(
              sortType: SongSortType.TITLE,
              orderType: OrderType.ASC_OR_SMALLER,
              uriType: UriType.EXTERNAL,
              ignoreCase: true,
            );

            localTracks = songs
                .where((s) =>
                    (s.isMusic ?? false) &&
                    s.duration != null &&
                    s.duration! > 0)
                .map((s) => Track(
                      id: 'local_${s.id}',
                      title: s.title,
                      artist: s.artist ?? 'Unknown',
                      url: s.uri ?? s.data,
                      isLocal: true,
                      localPath: s.data,
                      durationMs: s.duration,
                    ))
                .toList();
          }
        } catch (e) {
          // Local scan failed
        }
      }

      setState(() {
        _allTracks = [...demoTracks, ...localTracks];
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    List<Track> base = _allTracks;

    if (_currentTab == 'favorites') {
      base = _allTracks
          .where((t) => widget.storageService.isFavorite(t.id))
          .toList();
    } else if (_currentTab == 'local') {
      base = _allTracks.where((t) => t.isLocal).toList();
    }

    if (query.isEmpty) {
      _filteredTracks = base;
    } else {
      _filteredTracks = base
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              t.artist.toLowerCase().contains(query))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'کتابخانه',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: IconThemeData(color: AppTheme.iconActive),
        actions: [
          IconButton(
            onPressed: _pickCustomFolder,
            icon: Icon(Icons.folder_open, color: AppTheme.textSecondary),
            tooltip: 'انتخاب پوشه موزیک',
          ),
          IconButton(
            onPressed: _loadTracks,
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'اسکن مجدد',
          ),
          if (widget.storageService.getCustomFolderPath() != null)
            IconButton(
              onPressed: _clearCustomFolder,
              icon: Icon(Icons.folder_delete_outlined,
                  color: AppTheme.textSecondary),
              tooltip: 'حذف پوشه انتخابی',
            ),
          IconButton(
            onPressed: widget.onOpenSettings,
            icon: Icon(Icons.settings, color: AppTheme.textSecondary),
            tooltip: 'تنظیمات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'همه'),
            Tab(text: 'علاقه‌مندی'),
            Tab(text: 'محلی'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.storageService.getCustomFolderPath() != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.accent.withOpacity(AppTheme.isDark ? 0.15 : 0.10),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: AppTheme.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.storageService.getCustomFolderPath()!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _applyFilter()),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'جستجو...',
                hintStyle: TextStyle(color: AppTheme.textFaint),
                filled: true,
                fillColor: AppTheme.surfaceSoft,
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilter());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_filteredTracks.length} آهنگ',
                    style:
                        TextStyle(color: AppTheme.textFaint, fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accent),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text('خطا در بارگذاری',
                                style: TextStyle(
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadTracks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                              ),
                              child: const Text('تلاش مجدد'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTracks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.library_music,
                                    color: AppTheme.textFaint, size: 64),
                                const SizedBox(height: 16),
                                Text('هیچ آهنگی یافت نشد',
                                    style: TextStyle(
                                        color: AppTheme.textMuted)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _pickCustomFolder,
                                  icon: const Icon(Icons.folder_open,
                                      color: AppTheme.accent),
                                  label: const Text(
                                    'انتخاب پوشه موزیک',
                                    style: TextStyle(color: AppTheme.accent),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _filteredTracks.length,
                            itemBuilder: (context, index) {
                              final track = _filteredTracks[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: TrackTile(
                                  track: track,
                                  isCurrentTrack:
                                      track.id == widget.currentTrackId,
                                  isFavorite: widget.storageService
                                      .isFavorite(track.id),
                                  onTap: () {
                                    widget.onPlayTrack(
                                        track, _filteredTracks);
                                  },
                                  onFavoriteTap: () async {
                                    await widget.storageService
                                        .toggleFavorite(track);
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
