/// User-marked favourite surahs, stored as a sorted set of surah numbers.
abstract interface class FavoritesRepository {
  Set<int> load();
  Future<void> save(Set<int> favorites);
}
