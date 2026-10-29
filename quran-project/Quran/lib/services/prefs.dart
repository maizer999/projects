import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs._(this._p);
  final SharedPreferences _p;

  static Future<Prefs> create() async =>
      Prefs._(await SharedPreferences.getInstance());

  String getString(String k, String def) => _p.getString(k) ?? def;
  int getInt(String k, int def) => _p.getInt(k) ?? def;
  bool getBool(String k, bool def) => _p.getBool(k) ?? def;

  Future<void> setString(String k, String v) => _p.setString(k, v);
  Future<void> setInt(String k, int v) => _p.setInt(k, v);
  Future<void> setBool(String k, bool v) => _p.setBool(k, v);

  List<T> getJsonList<T>(String k, T Function(Map<String, dynamic>) fromJson) {
    final raw = _p.getString(k);
    if (raw == null) return <T>[];
    final list = json.decode(raw) as List;
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setJsonList(String k, List<Map<String, dynamic>> v) =>
      _p.setString(k, json.encode(v));

  List<int> getIntList(String k) {
    final raw = _p.getString(k);
    if (raw == null) return <int>[];
    return (json.decode(raw) as List).map((e) => e as int).toList();
  }

  Future<void> setIntList(String k, List<int> v) =>
      _p.setString(k, json.encode(v));
}
