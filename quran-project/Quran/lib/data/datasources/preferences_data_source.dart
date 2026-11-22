import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences so repositories don't depend on the
/// plugin directly (and tests can use `SharedPreferences.setMockInitialValues`).
class PreferencesDataSource {
  const PreferencesDataSource(this._prefs);
  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);
  double? getDouble(String key) => _prefs.getDouble(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);
}
