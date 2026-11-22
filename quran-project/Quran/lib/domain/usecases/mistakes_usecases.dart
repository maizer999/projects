import '../repositories/mistakes_repository.dart';

class LoadMistakes {
  const LoadMistakes(this._repo);
  final MistakesRepository _repo;
  Map<int, Set<int>> call() => _repo.load();
}

/// Marks or un-marks one ayah and persists the result.
/// Returns the new map; [ToggleMistakeResult.marked] tells the UI which way.
class ToggleAyahMistake {
  const ToggleAyahMistake(this._repo);
  final MistakesRepository _repo;

  Future<ToggleMistakeResult> call(
    Map<int, Set<int>> current, {
    required int surah,
    required int ayahNumber,
  }) async {
    final next = {for (final e in current.entries) e.key: {...e.value}};
    final set = next.putIfAbsent(surah, () => <int>{});
    final marked = set.add(ayahNumber);
    if (!marked) set.remove(ayahNumber);
    if (set.isEmpty) next.remove(surah);
    await _repo.save(next);
    return ToggleMistakeResult(next, marked);
  }
}

class ToggleMistakeResult {
  const ToggleMistakeResult(this.mistakes, this.marked);
  final Map<int, Set<int>> mistakes;
  final bool marked;
}

class ResetSurahMistakes {
  const ResetSurahMistakes(this._repo);
  final MistakesRepository _repo;

  Future<Map<int, Set<int>>> call(Map<int, Set<int>> current, int surah) async {
    final next = {for (final e in current.entries) e.key: {...e.value}}..remove(surah);
    await _repo.save(next);
    return next;
  }
}
