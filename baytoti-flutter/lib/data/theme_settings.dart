import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  static const _k = 'bayti_theme_preset';
  static const _defaultId = 'teal';

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_k) ?? _defaultId;
  }

  static Future<void> set(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k, id);
  }
}
