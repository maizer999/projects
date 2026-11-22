/// Per-surah set of ayah numbers marked as memorisation mistakes.
abstract interface class MistakesRepository {
  Map<int, Set<int>> load();
  Future<void> save(Map<int, Set<int>> mistakes);
}
