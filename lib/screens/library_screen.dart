import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/track.dart';
import '../services/storage_service.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  final PlayerCallback onPlayTrack;
  final StorageService storageService;
  final String? currentTrackId;

  const LibraryScreen({
    super.key,
    required this.onPlayTrack,
    required this.storageService,
    this.currentTrackId,
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

  Future<void> _pickCustomFolder() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'پوشه موزیک خود را انتخاب کنید',
        lockParentWindow: true,
      );

      if (path != null && path.isNotEmpty) {
        await widget.storageService.setCustomFolderPath(path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('پوشه انتخاب شد: $path'),
              backgroundColor: const Color(0xFF8B5CF6),
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
    _loadTracks();
  }

  Future<List<Track>> _scanFolder(String path) async {
    final List<Track> tracks = [];
    final extensions = {'.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'};

    try {
      final dir = Directory(path);
      if (!await dir.exists()) return tracks;

      final entities = await dir.list(recursive: true, followLinks: false).toList();

      int index = 0;
      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (extensions.any((e) => ext.endsWith(e))) {
            index++;
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final title = fileName.split('.').first;

            tracks.add(Track(
              id: 'folder_$index',
              title: title,
              artist: 'Local File',
              url: entity.path,
              isLocal: true,
              localPath: entity.path,
              durationMs: null,
            ));
          }
        }
      }

      tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (e) {
      // Scan failed
    }

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

      // اسکن پوشه سفارشی (اگر انتخاب شده)
      if (customPath != null && customPath.isNotEmpty) {
        localTracks = await _scanFolder(customPath);
      } else {
        // اسکن خودکار از Media Store
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
                .where((s) => (s.isMusic ?? false) && s.duration != null && s.duration! > 0)
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
        _filteredTracks = _allTracks;
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
      setState(() => _filteredTracks = base);
    } else {
      setState(() {
        _filteredTracks = base
            .where((t) =>
                t.title.toLowerCase().contains(query) ||
                t.artist.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'کتابخانه',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _pickCustomFolder,
            icon: const Icon(Icons.folder_open, color: Colors.white70),
            tooltip: 'انتخاب پوشه موزیک',
          ),
          if (widget.storageService.getCustomFolderPath() != null)
            IconButton(
              onPressed: _clearCustomFolder,
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: 'حذف پوشه انتخابی',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
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
              color: const Color.fromRGBO(139, 92, 246, 0.15),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder,
                    color: Color(0xFF8B5CF6),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.storageService.getCustomFolderPath()!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'جستجو...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
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
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'خطا در بارگذاری',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadTracks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
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
                                const Icon(
                                  Icons.library_music,
                                  color: Colors.white24,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'هیچ آهنگی یافت نشد',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _pickCustomFolder,
                                  icon: const Icon(
                                    Icons.folder_open,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  label: const Text(
                                    'انتخاب پوشه موزیک',
                                    style: TextStyle(color: Color(0xFF8B5CF6)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                  isFavorite:
                                      widget.storageService.isFavorite(track.id),
                                  onTap: () {
                                    widget.onPlayTrack(track, _filteredTracks);
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
