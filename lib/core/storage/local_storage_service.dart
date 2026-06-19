import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Typed wrapper over SharedPreferences for non-sensitive app settings.
///
/// For sensitive data (tokens, keys): use SecureStorageService instead.
/// Call [initialize] during app startup before accessing any values.
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService _instance = LocalStorageService._();
  static LocalStorageService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('LocalStorageService initialized');
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'LocalStorageService not initialized. Call initialize() first.');
    return _prefs!;
  }

  // ── String ─────────────────────────────────────────────────────────────
  String? getString(String key) => _p.getString(key);
  Future<void> setString(String key, String value) => _p.setString(key, value);

  // ── Bool ───────────────────────────────────────────────────────────────
  bool? getBool(String key) => _p.getBool(key);
  Future<void> setBool(String key, bool value) => _p.setBool(key, value);

  // ── Int ────────────────────────────────────────────────────────────────
  int? getInt(String key) => _p.getInt(key);
  Future<void> setInt(String key, int value) => _p.setInt(key, value);

  // ── Double ─────────────────────────────────────────────────────────────
  double? getDouble(String key) => _p.getDouble(key);
  Future<void> setDouble(String key, double value) => _p.setDouble(key, value);

  // ── StringList ────────────────────────────────────────────────────────
  List<String>? getStringList(String key) => _p.getStringList(key);
  Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);

  // ── Removal ───────────────────────────────────────────────────────────
  Future<void> remove(String key) => _p.remove(key);
  Future<void> clear() => _p.clear();
  bool containsKey(String key) => _p.containsKey(key);
}
