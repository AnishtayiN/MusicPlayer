import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';
import '../services/player_service.dart';
import '../services/storage_service.dart';
import '../utils/web_bridge.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  final PlayerCallback onPlayTrack;
  final StorageService storageService;
  final PlayerService playerService;
  final String? currentTrackId;
  final VoidCallback onOpenSettings;

  const LibraryScreen({
    super.key,
    required this.onPlayTrack,
    required this.storageService,
    required this.playerService,
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab =
              ['all', 'favorites', 'local', 'history'][_tabController.index];
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

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color ?? AppTheme.surface,
        duration: const Duration(seconds: 2)));
  }

  String _baseName(String p) {
    final norm = p.replaceAll('\\', '/');
    final name = norm.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // ---------- منو ----------
  void _onTrackMenu(Track track, String action) {
    if (action == 'rename') _renameTrack(track);
    if (action == 'share') _shareTrack(track);
    if (action == 'delete') _confirmDelete(track);
  }

  Future<void> _renameTrack(Track track) async {
    final path = track.localPath;
    if (!track.isLocal || path == null) {
      _snack('تغییر نام فقط برای فایل‌های محلی امکان‌پذیر است');
      return;
    }
    final c = TextEditingController(text: track.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تغییر نام آهنگ',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: c,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'نام جدید',
            hintStyle: TextStyle(color: AppTheme.textFaint),
            filled: true, fillColor: AppTheme.surfaceSoft,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('انصراف', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
              child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok != true) return;
    final newName = c.text.trim();
    if (newName.isEmpty) return;
    final sep = path.contains('\\') ? '\\' : '/';
    final ls = path.lastIndexOf(sep);
    final dir = ls >= 0 ? path.substring(0, ls + 1) : '';
    final dot = path.lastIndexOf('.');
    final ext = dot > ls ? path.substring(dot) : '';
    final newPath = '$dir$newName$ext';
    bool ok2 = false;
    if (kIsWeb) {
      ok2 = await renameFileNative(path, newPath);
    } else {
      try {
        final f = File(path);
        if (await f.exists()) { await f.rename(newPath); ok2 = true; }
      } catch (_) {}
    }
    _snack(ok2 ? 'نام آهنگ تغییر کرد' : 'خطا در تغییر نام');
    if (ok2) _loadTracks();
  }

  Future<void> _shareTrack(Track track) async {
    if (kIsWeb) {
      if (track.localPath != null) {
        revealFileNative(track.localPath!);
        _snack('پوشه فایل باز شد');
      } else {
        _snack('ارسال فقط برای فایل‌های محلی');
      }
      return;
    }
    if (track.isLocal && track.localPath != null) {
      await Share.shareXFiles([XFile(track.localPath!)]);
    } else {
      await Share.share(track.url);
    }
  }

  Future<void> _confirmDelete(Track track) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف آهنگ', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('«${track.title}» حذف شود؟',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('انصراف', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('حذف')),
        ],
      ),
    );
    if (conf != true) return;
    if (track.isLocal && track.localPath != null) {
      bool ok = false;
      if (kIsWeb) {
        ok = await deleteFileNative(track.localPath!);
      } else {
        try {
          final f = File(track.localPath!);
          if (await f.exists()) { await f.delete(); ok = true; }
        } catch (_) {}
      }
      _snack(ok ? 'آهنگ حذف شد' : 'خطا در حذف');
      if (ok) _loadTracks();
    } else {
      setState(() {
        _allTracks.removeWhere((t) => t.id == track.id);
        _applyFilter();
      });
      _snack('از لیست حذف شد');
    }
  }

  // ---------- اسکن ----------
  Future<void> _pickCustomFolder() async {
    try {
      String? path;
      if (kIsWeb) {
        if (!isElectronBridgeAvailable) {
          _snack('انتخاب پوشه فقط در نسخه دسکتاپ فعال است', color: Colors.redAccent);
          return;
        }
        path = await selectFolderNative();
      } else {
        path = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'پوشه موزیک خود را انتخاب کنید');
      }
      if (path != null && path.isNotEmpty) {
        await widget.storageService.setCustomFolderPath(path);
        _snack('پوشه انتخاب شد: $path', color: AppTheme.accent);
        _loadTracks();
      }
    } catch (e) {
      _snack('خطا در انتخاب پوشه: $e', color: Colors.redAccent);
    }
  }

  Future<void> _clearCustomFolder() async {
    await widget.storageService.setCustomFolderPath(null);
    _snack('پوشه انتخابی حذف شد');
    _loadTracks();
  }

  Future<List<Track>> _scanFolder(String path) async {
    final tracks = <Track>[];
    final exts = {'.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'};
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return tracks;
      final entities = await dir.list(recursive: true, followLinks: false).toList();
      for (final e in entities) {
        if (e is File && exts.any((x) => e.path.toLowerCase().endsWith(x))) {
          tracks.add(Track(
            id: 'folder_${e.path.hashCode}',
            title: _baseName(e.path),
            artist: 'Local File',
            url: e.path,
            isLocal: true,
            localPath: e.path,
          ));
        }
      }
      tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (_) {}
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
              localPath: p,
            ))
        .toList();
    tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return tracks;
  }

  Future<void> _loadTracks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final demoTracks = <Track>[
        Track(id: 'demo_1', title: 'Neon Drive', artist: 'SoundHelix',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            artworkUrl: 'https://picsum.photos/seed/neon/700/700', durationMs: 372000),
        Track(id: 'demo_2', title: 'Midnight Pulse', artist: 'SoundHelix',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            artworkUrl: 'https://picsum.photos/seed/midnight/700/700', durationMs: 420000),
        Track(id: 'demo_3', title: 'Cyber Sunset', artist: 'SoundHelix',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            artworkUrl: 'https://picsum.photos/seed/cyber/700/700', durationMs: 395000),
        Track(id: 'demo_4', title: 'Aurora Bass', artist: 'SoundHelix',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            artworkUrl: 'https://picsum.photos/seed/aurora/700/700', durationMs: 360000),
      ];

      List<Track> localTracks = [];
      final customPath = widget.storageService.getCustomFolderPath();

      if (customPath != null && customPath.isNotEmpty) {
        localTracks = kIsWeb
            ? await _scanFolderWeb(customPath)
            : await _scanFolder(customPath);
      } else if (kIsWeb) {
        // اسکن خودکار پوشه Music ویندوز
        final musicDir = await getMusicDirNative();
        if (musicDir != null) localTracks = await _scanFolderWeb(musicDir);
      } else {
        try {
          final st = await Permission.audio.status;
          var fs = st;
          if (!st.isGranted) fs = await Permission.audio.request();
          if (!fs.isGranted) fs = await Permission.storage.request();
          if (fs.isGranted) {
            final songs = await _audioQuery.querySongs(
              sortType: SongSortType.TITLE,
              orderType: OrderType.ASC_OR_SMALLER,
              uriType: UriType.EXTERNAL,
              ignoreCase: true,
            );
            localTracks = songs
                .where((s) => (s.isMusic ?? false) &&
                    s.duration != null && s.duration! > 0)
                .map((s) => Track(
                      id: 'local_${s.id}',
                      title: s.title,
                      artist: s.artist ?? 'Unknown',
                      url: s.uri ?? s.data,
                      isLocal: true,
                      localPath: s.data,
                      durationMs: s.duration,
                      album: s.album,
                      artworkId: s.id,
                    ))
                .toList();
          }
        } catch (_) {}
      }

      _allTracks = [...demoTracks, ...localTracks];
      _applyFilter();

      // بازیابی آخرین پخش
      if (widget.playerService.currentTrack == null) {
        final lastId = widget.storageService.getLastTrackId();
        final idx = _allTracks.indexWhere((t) => t.id == lastId);
        if (idx >= 0) {
          await widget.playerService.loadTracks(_allTracks,
              startIndex: idx, autoplay: false);
          final ms = widget.storageService.getLastPositionMs();
          if (ms > 0) {
            await widget.playerService.seek(Duration(milliseconds: ms));
          }
        }
      }

      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    List<Track> base;
    if (_currentTab == 'favorites') {
      base = _allTracks.where((t) => widget.storageService.isFavorite(t.id)).toList();
    } else if (_currentTab == 'local') {
      base = _allTracks.where((t) => t.isLocal).toList();
    } else if (_currentTab == 'history') {
      base = widget.storageService.getHistory();
    } else {
      base = _allTracks;
    }
    _filteredTracks = q.isEmpty
        ? base
        : base.where((t) => t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('کتابخانه', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.iconActive),
        actions: [
          IconButton(onPressed: _pickCustomFolder,
              icon: Icon(Icons.folder_open, color: AppTheme.textSecondary),
              tooltip: 'انتخاب پوشه موزیک'),
          IconButton(onPressed: _loadTracks,
              icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
              tooltip: 'اسکن مجدد'),
          if (widget.storageService.getCustomFolderPath() != null)
            IconButton(onPressed: _clearCustomFolder,
                icon: Icon(Icons.folder_delete_outlined, color: AppTheme.textSecondary),
                tooltip: 'حذف پوشه انتخابی'),
          IconButton(onPressed: widget.onOpenSettings,
              icon: Icon(Icons.settings, color: AppTheme.textSecondary),
              tooltip: 'تنظیمات'),
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
            Tab(text: 'تاریخچه'),
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
              child: Row(children: [
                Icon(Icons.folder, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    widget.storageService.getCustomFolderPath()!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              ]),
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
                filled: true, fillColor: AppTheme.surfaceSoft,
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () { _searchController.clear(); setState(() => _applyFilter()); })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('${_filteredTracks.length} آهنگ',
                    style: TextStyle(color: AppTheme.textFaint, fontSize: 12)),
              ]),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _error != null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text('خطا در بارگذاری', style: TextStyle(color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadTracks,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                              child: const Text('تلاش مجدد')),
                        ]))
                    : _filteredTracks.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_music, color: AppTheme.textFaint, size: 64),
                              const SizedBox(height: 16),
                              Text('هیچ آهنگی یافت نشد', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _pickCustomFolder,
                                icon: Icon(Icons.folder_open, color: AppTheme.accent),
                                label: Text('انتخاب پوشه موزیک', style: TextStyle(color: AppTheme.accent)),
                              ),
                            ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _filteredTracks.length,
                            itemBuilder: (ctx, i) {
                              final track = _filteredTracks[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: TrackTile(
                                  track: track,
                                  isCurrentTrack: track.id == widget.currentTrackId,
                                  isFavorite: widget.storageService.isFavorite(track.id),
                                  onTap: () => widget.onPlayTrack(track, _filteredTracks),
                                  onFavoriteTap: () async {
                                    await widget.storageService.toggleFavorite(track);
                                    setState(() {});
                                  },
                                  onMenuAction: (a) => _onTrackMenu(track, a),
                                ),
                              );
                            }),
          ),
        ],
      ),
    );
  }
}
