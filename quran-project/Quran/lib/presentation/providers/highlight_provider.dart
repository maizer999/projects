import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependency_providers.dart';
import 'mistakes_provider.dart';
import 'player_provider.dart';
import 'reader_provider.dart';

/// Ayah ids to wash on the page: the reciting ayah in listen mode, the
/// marked mistakes in memorize mode.
final highlightedAyahsProvider = Provider<Set<int>>((ref) {
  final mode = ref.watch(readerProvider.select((s) => s.mode));
  if (mode == ReaderMode.listen) {
    final playing = ref.watch(playingAyahProvider);
    return playing == null ? const <int>{} : {playing.id};
  }
  final mistakes = ref.watch(mistakesProvider);
  final ayahsOf = ref.watch(getSurahAyahsProvider);
  return {
    for (final e in mistakes.entries)
      for (final n in e.value)
        if (n >= 1 && n <= ayahsOf(e.key).length) ayahsOf(e.key)[n - 1].id,
  };
});
