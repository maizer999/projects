import '../repositories/favorites_repository.dart';

class LoadFavorites {
  const LoadFavorites(this._repo);
  final FavoritesRepository _repo;
  Set<int> call() => _repo.load();
}

/// Adds or removes a surah number; returns the new set.
class ToggleSurahFavorite {
  const ToggleSurahFavorite(this._repo);
  final FavoritesRepository _repo;

  Future<Set<int>> call(Set<int> current, int surah) async {
    final next = {...current};
    if (!next.add(surah)) next.remove(surah);
    await _repo.save(next);
    return next;
  }
}
