import 'package:hive_flutter/hive_flutter.dart';
import '../models/track.dart';

class StorageService {
  Box<Track>? _favoritesBoxRef;
  Box<Track>? _historyBoxRef;
  Box<dynamic>? _settingsBoxRef;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // Ensure Hive is initialized (in case main.dart didn't do it properly)
      if (!Hive.isInitialized) {
        await Hive.initFlutter();
        print('✅ Hive initialized in StorageService');
      }
      
      // Register Adapter safely
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TrackAdapter());
        print('✅ TrackAdapter registered in StorageService');
      }
      
      // Open boxes with error handling
      try {
        _favoritesBoxRef = await Hive.openBox<Track>('favorites');
        print('✅ Favorites box opened');
      } catch (e) {
        print('❌ Error opening favorites box: $e');
        _favoritesBoxRef = null;
      }
      
      try {
        _historyBoxRef = await Hive.openBox<Track>('history');
        print('✅ History box opened');
      } catch (e) {
        print('❌ Error opening history box: $e');
        _historyBoxRef = null;
      }
      
      try {
        _settingsBoxRef = await Hive.openBox('settings');
        print('✅ Settings box opened');
      } catch (e) {
        print('❌ Error opening settings box: $e');
        _settingsBoxRef = null;
      }
      
      _initialized = true;
      print('✅ StorageService initialization complete');
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR in StorageService.init: $e');
      print('Stack Trace: $stackTrace');
      _initialized = false;
      // Don't throw - let the app continue even if storage fails
    }
  }

  Box<Track>? get _favoritesBox {
    if (!_initialized || _favoritesBoxRef == null) {
      print('⚠️ Favorites box not available');
      return null;
    }
    return _favoritesBoxRef;
  }

  Box<Track>? get _historyBox {
    if (!_initialized || _historyBoxRef == null) {
      print('⚠️ History box not available');
      return null;
    }
    return _historyBoxRef;
  }

  Box<dynamic>? get _settingsBox {
    if (!_initialized || _settingsBoxRef == null) {
      print('⚠️ Settings box not available');
      return null;
    }
    return _settingsBoxRef;
  }

  List<Track> getFavorites() {
    final box = _favoritesBox;
    if (box == null) return [];
    return box.values.toList();
  }

  Future<void> toggleFavorite(Track track) async {
    final box = _favoritesBox;
    if (box == null) {
      print('⚠️ Cannot toggle favorite: box not available');
      return;
    }
    if (box.containsKey(track.id)) {
      await box.delete(track.id);
    } else {
      await box.put(track.id, track);
    }
  }

  bool isFavorite(String trackId) {
    final box = _favoritesBox;
    if (box == null) return false;
    return box.containsKey(trackId);
  }

  List<Track> getHistory() {
    final box = _historyBox;
    if (box == null) return [];
    return box.values.toList().reversed.toList();
  }

  Future<void> addHistory(Track t) async {
    final box = _historyBox;
    if (box == null) {
      print('⚠️ Cannot add to history: box not available');
      return;
    }
    await box.put(t.id, t);
  }

  String? getCustomFolderPath() {
    final box = _settingsBox;
    if (box == null) return null;
    return box.get('custom_folder_path');
  }
  
  Future<void> setCustomFolderPath(String? p) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('custom_folder_path', p);
  }

  bool isDarkTheme() {
    final box = _settingsBox;
    if (box == null) return true; // Default to dark theme
    return box.get('theme_dark', defaultValue: true);
  }
  
  Future<void> setDarkTheme(bool v) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('theme_dark', v);
  }

  String getDarkAccent() {
    final box = _settingsBox;
    if (box == null) return 'purple';
    return box.get('accent_dark', defaultValue: 'purple');
  }
  
  Future<void> setDarkAccent(String v) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('accent_dark', v);
  }

  String getLightAccent() {
    final box = _settingsBox;
    if (box == null) return 'blue';
    return box.get('accent_light', defaultValue: 'blue');
  }
  
  Future<void> setLightAccent(String v) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('accent_light', v);
  }

  double getVolume() {
    final box = _settingsBox;
    if (box == null) return 1.0;
    final val = box.get('volume', defaultValue: 1.0);
    return (val as num).toDouble();
  }
  
  Future<void> setVolume(double v) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('volume', v);
  }

  double getSpeed() {
    final box = _settingsBox;
    if (box == null) return 1.0;
    final val = box.get('speed', defaultValue: 1.0);
    return (val as num).toDouble();
  }
  
  Future<void> setSpeed(double v) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('speed', v);
  }

  String? getLastTrackId() {
    final box = _settingsBox;
    if (box == null) return null;
    return box.get('last_track_id');
  }
  
  int getLastPositionMs() {
    final box = _settingsBox;
    if (box == null) return 0;
    return box.get('last_position_ms', defaultValue: 0);
  }
  
  Future<void> setLastSession(String id, int ms) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('last_track_id', id);
    await box.put('last_position_ms', ms);
  }

  String? getSavedLyrics(String id) {
    final box = _settingsBox;
    if (box == null) return null;
    return box.get('lyrics_$id');
  }
  
  Future<void> setSavedLyrics(String id, String text) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('lyrics_$id', text);
  }

  bool getSkipUpdate(String v) {
    final box = _settingsBox;
    if (box == null) return false;
    return box.get('skip_$v', defaultValue: false);
  }
  
  Future<void> setSkipUpdate(String v, bool s) async {
    final box = _settingsBox;
    if (box == null) return;
    await box.put('skip_$v', s);
  }
}
