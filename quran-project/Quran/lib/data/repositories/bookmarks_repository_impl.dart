import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../datasources/preferences_data_source.dart';

class BookmarksRepositoryImpl implements BookmarksRepository {
  const BookmarksRepositoryImpl(this._prefs);
  final PreferencesDataSource _prefs;

  @override
  Set<int> load() {
    final raw = _prefs.getString(StorageKeys.bookmarkedPages);
    if (raw == null || raw.isEmpty) return <int>{};
    final decoded = json.decode(raw) as List;
    return decoded.map((e) => e as int).toSet();
  }

  @override
  Future<void> save(Set<int> pages) => _prefs.setString(
        StorageKeys.bookmarkedPages,
        json.encode(pages.toList()..sort()),
      );
}
