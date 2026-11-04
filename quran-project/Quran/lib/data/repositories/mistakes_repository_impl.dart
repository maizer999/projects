import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../domain/repositories/mistakes_repository.dart';
import '../datasources/preferences_data_source.dart';

class MistakesRepositoryImpl implements MistakesRepository {
  const MistakesRepositoryImpl(this._prefs);
  final PreferencesDataSource _prefs;

  @override
  Map<int, Set<int>> load() {
    final raw = _prefs.getString(StorageKeys.surahMistakeAyahs);
    if (raw == null || raw.isEmpty) return <int, Set<int>>{};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(int.parse(k), (v as List).map((e) => e as int).toSet()),
    );
  }

  @override
  Future<void> save(Map<int, Set<int>> mistakes) => _prefs.setString(
        StorageKeys.surahMistakeAyahs,
        json.encode(mistakes.map((k, v) => MapEntry(k.toString(), v.toList()..sort()))),
      );
}
