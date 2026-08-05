import 'package:hive_flutter/hive_flutter.dart';
import '../models/track.dart';

class StorageService {
  Box<Track>? _favoritesBoxRef;
  Box<Track>? _historyBoxRef;
  Box<dynamic>? _settingsBoxRef;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // Hive should be initialized in main.dart before calling this
    try {
      Hive.registerAdapter(TrackAdapter());
    } catch (_) {}
    
    _favoritesBoxRef = await Hive.openBox<Track>('favorites');
    _historyBoxRef = await Hive.openBox<Track>('history');
    _settingsBoxRef = await Hive.openBox('settings');
    _initialized = true;
  }

  Box<Track> get _favoritesBox {
    if (_favoritesBoxRef == null) throw StateError('StorageService not initialized');
    return _favoritesBoxRef!;
  }

  Box<Track> get _historyBox {
    if (_historyBoxRef == null) throw StateError('StorageService not initialized');
    return _historyBoxRef!;
  }

  Box<dynamic> get _settingsBox {
    if (_settingsBoxRef == null) throw StateError('StorageService not initialized');
    return _settingsBoxRef!;
  }

  List<Track> getFavorites() => _favoritesBox.values.toList();

  Future<void> toggleFavorite(Track track) async {
    if (_favoritesBox.containsKey(track.id)) {
      await _favoritesBox.delete(track.id);
    } else {
      await _favoritesBox.put(track.id, track);
    }
  }

  bool isFavorite(String trackId) => _favoritesBox.containsKey(trackId);

  List<Track> getHistory() => _historyBox.values.toList().reversed.toList();

  Future<void> addHistory(Track t) async => _historyBox.put(t.id, t);

  String? getCustomFolderPath() => _settingsBox.get('custom_folder_path');
  Future<void> setCustomFolderPath(String? p) async =>
      _settingsBox.put('custom_folder_path', p);

  bool isDarkTheme() => _settingsBox.get('theme_dark', defaultValue: true);
  Future<void> setDarkTheme(bool v) async => _settingsBox.put('theme_dark', v);

  String getDarkAccent() =>
      _settingsBox.get('accent_dark', defaultValue: 'purple');
  Future<void> setDarkAccent(String v) async =>
      _settingsBox.put('accent_dark', v);

  String getLightAccent() =>
      _settingsBox.get('accent_light', defaultValue: 'blue');
  Future<void> setLightAccent(String v) async =>
      _settingsBox.put('accent_light', v);

  double getVolume() => (_settingsBox.get('volume', defaultValue: 1.0) as num).toDouble();
  Future<void> setVolume(double v) async => _settingsBox.put('volume', v);

  double getSpeed() => (_settingsBox.get('speed', defaultValue: 1.0) as num).toDouble();
  Future<void> setSpeed(double v) async => _settingsBox.put('speed', v);

  String? getLastTrackId() => _settingsBox.get('last_track_id');
  int getLastPositionMs() => _settingsBox.get('last_position_ms', defaultValue: 0);
  Future<void> setLastSession(String id, int ms) async {
    await _settingsBox.put('last_track_id', id);
    await _settingsBox.put('last_position_ms', ms);
  }

  String? getSavedLyrics(String id) => _settingsBox.get('lyrics_$id');
  Future<void> setSavedLyrics(String id, String text) async =>
      _settingsBox.put('lyrics_$id', text);

  bool getSkipUpdate(String v) =>
      _settingsBox.get('skip_$v', defaultValue: false);
  Future<void> setSkipUpdate(String v, bool s) async =>
      _settingsBox.put('skip_$v', s);
}
