import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependency_providers.dart';

/// surahNumber → ayah numbers (in surah) marked as mistakes.
final mistakesProvider =
    NotifierProvider<MistakesNotifier, Map<int, Set<int>>>(MistakesNotifier.new);

class MistakesNotifier extends Notifier<Map<int, Set<int>>> {
  @override
  Map<int, Set<int>> build() => ref.watch(loadMistakesProvider)();

  /// Returns true if the ayah is now marked.
  Future<bool> toggle({required int surah, required int ayahNumber}) async {
    final result = await ref.read(toggleAyahMistakeProvider)(
      state,
      surah: surah,
      ayahNumber: ayahNumber,
    );
    state = result.mistakes;
    return result.marked;
  }

  Future<void> reset(int surah) async {
    state = await ref.read(resetSurahMistakesProvider)(state, surah);
  }
}

final mistakeCountProvider = Provider.family<int, int>(
  (ref, surah) => ref.watch(mistakesProvider.select((m) => m[surah]?.length ?? 0)),
);
