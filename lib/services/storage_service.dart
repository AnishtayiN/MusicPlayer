import 'package:hive_flutter/hive_flutter.dart';
import '../models/track.dart';

class StorageService {
  late Box<Track> _favoritesBoxRef;
  late Box<Track> _historyBoxRef;
  late Box<dynamic> _settingsBoxRef;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrackAdapter());
    _favoritesBoxRef = await Hive.openBox<Track>('favorites');
    _historyBoxRef = await Hive.openBox<Track>('history');
    _settingsBoxRef = await Hive.openBox('settings');
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

  List<Track> getHistory() => _historyBoxRef.values.toList().reversed.toList();

  Future<void> addHistory(Track t) async => _historyBoxRef.put(t.id, t);

  String? getCustomFolderPath() => _settingsBoxRef.get('custom_folder_path');
  Future<void> setCustomFolderPath(String? p) async =>
      _settingsBoxRef.put('custom_folder_path', p);

  bool isDarkTheme() => _settingsBoxRef.get('theme_dark', defaultValue: true);
  Future<void> setDarkTheme(bool v) async => _settingsBoxRef.put('theme_dark', v);

  String getDarkAccent() =>
      _settingsBoxRef.get('accent_dark', defaultValue: 'purple');
  Future<void> setDarkAccent(String v) async =>
      _settingsBoxRef.put('accent_dark', v);

  String getLightAccent() =>
      _settingsBoxRef.get('accent_light', defaultValue: 'blue');
  Future<void> setLightAccent(String v) async =>
      _settingsBoxRef.put('accent_light', v);

  double getVolume() => (_settingsBoxRef.get('volume', defaultValue: 1.0) as num).toDouble();
  Future<void> setVolume(double v) async => _settingsBoxRef.put('volume', v);

  double getSpeed() => (_settingsBoxRef.get('speed', defaultValue: 1.0) as num).toDouble();
  Future<void> setSpeed(double v) async => _settingsBoxRef.put('speed', v);

  String? getLastTrackId() => _settingsBoxRef.get('last_track_id');
  int getLastPositionMs() => _settingsBoxRef.get('last_position_ms', defaultValue: 0);
  Future<void> setLastSession(String id, int ms) async {
    await _settingsBoxRef.put('last_track_id', id);
    await _settingsBoxRef.put('last_position_ms', ms);
  }

  String? getSavedLyrics(String id) => _settingsBoxRef.get('lyrics_$id');
  Future<void> setSavedLyrics(String id, String text) async =>
      _settingsBoxRef.put('lyrics_$id', text);

  bool getSkipUpdate(String v) =>
      _settingsBoxRef.get('skip_$v', defaultValue: false);
  Future<void> setSkipUpdate(String v, bool s) async =>
      _settingsBoxRef.put('skip_$v', s);
}
