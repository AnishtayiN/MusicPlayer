import 'package:hive_flutter/hive_flutter.dart';
import '../models/track.dart';

class StorageService {
  static const String _favoritesBox = 'favorites';
  static const String _playlistsBox = 'playlists';
  static const String _settingsBox = 'settings';

  late Box<Track> _favoritesBoxRef;
  late Box<List> _playlistsBoxRef;
  late Box<dynamic> _settingsBoxRef;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrackAdapter());

    _favoritesBoxRef = await Hive.openBox<Track>(_favoritesBox);
    _playlistsBoxRef = await Hive.openBox<List>(_playlistsBox);
    _settingsBoxRef = await Hive.openBox(_settingsBox);
  }

  List<Track> getFavorites() => _favoritesBoxRef.values.toList();

  Future<void> toggleFavorite(Track track) async {
    if (_favoritesBoxRef.containsKey(track.id)) {
      await _favoritesBoxRef.delete(track.id);
    } else {
      await _favoritesBoxRef.put(track.id, track);
    }
  }

  bool isFavorite(String trackId) => _favoritesBoxRef.containsKey(trackId);

  List<Track> getPlaylist(String name) {
    final data = _playlistsBoxRef.get(name);
    if (data == null) return [];
    return data.cast<Track>();
  }

  Future<void> savePlaylist(String name, List<Track> tracks) async {
    await _playlistsBoxRef.put(name, tracks);
  }

  Future<void> deletePlaylist(String name) async {
    await _playlistsBoxRef.delete(name);
  }

  List<String> getPlaylistNames() =>
      _playlistsBoxRef.keys.cast<String>().toList();

  String? getLastVersion() => _settingsBoxRef.get('lastVersion');

  Future<void> setLastVersion(String version) async {
    await _settingsBoxRef.put('lastVersion', version);
  }

  bool getSkipUpdate(String version) =>
      _settingsBoxRef.get('skip_$version', defaultValue: false);

  Future<void> setSkipUpdate(String version, bool skip) async {
    await _settingsBoxRef.put('skip_$version', skip);
  }

  String? getCustomFolderPath() => _settingsBoxRef.get('custom_folder_path');

  Future<void> setCustomFolderPath(String? path) async {
    await _settingsBoxRef.put('custom_folder_path', path);
  }

  bool isDarkTheme() => _settingsBoxRef.get('theme_dark', defaultValue: true);

  Future<void> setDarkTheme(bool value) async {
    await _settingsBoxRef.put('theme_dark', value);
  }

  String getDarkAccent() =>
      _settingsBoxRef.get('accent_dark', defaultValue: 'purple');

  Future<void> setDarkAccent(String value) async {
    await _settingsBoxRef.put('accent_dark', value);
  }

  String getLightAccent() =>
      _settingsBoxRef.get('accent_light', defaultValue: 'blue');

  Future<void> setLightAccent(String value) async {
    await _settingsBoxRef.put('accent_light', value);
  }
}
