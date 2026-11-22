import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/preferences_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._prefs);
  final PreferencesDataSource _prefs;

  @override
  Set<int> load() {
    final raw = _prefs.getString(StorageKeys.favoriteSurahs);
    if (raw == null || raw.isEmpty) return <int>{};
    final decoded = json.decode(raw) as List;
    return decoded.map((e) => e as int).toSet();
  }

  @override
  Future<void> save(Set<int> favorites) => _prefs.setString(
        StorageKeys.favoriteSurahs,
        json.encode(favorites.toList()..sort()),
      );
}
