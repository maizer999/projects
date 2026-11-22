import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependency_providers.dart';

/// Surahs the user has marked as favourite (surah numbers).
final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.watch(loadFavoritesProvider)();

  Future<void> toggle(int surah) async {
    state = await ref.read(toggleSurahFavoriteProvider)(state, surah);
  }
}

final isFavoriteProvider = Provider.family<bool, int>(
  (ref, surah) => ref.watch(favoritesProvider.select((s) => s.contains(surah))),
);

/// Which list the drawer is showing — all surahs, favourites, or bookmarks.
enum PanelTab { all, favorites, bookmarks }

final panelTabProvider = NotifierProvider<PanelTabNotifier, PanelTab>(
  PanelTabNotifier.new,
);

class PanelTabNotifier extends Notifier<PanelTab> {
  @override
  PanelTab build() => PanelTab.all;

  void set(PanelTab tab) => state = tab;
}
