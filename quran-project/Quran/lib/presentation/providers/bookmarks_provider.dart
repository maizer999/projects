import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependency_providers.dart';

/// Mushaf pages the user bookmarked (المرجعية) — set of page numbers 1..604.
final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, Set<int>>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.watch(loadBookmarksProvider)();

  Future<void> toggle(int page) async {
    state = await ref.read(togglePageBookmarkProvider)(state, page);
  }
}

final isBookmarkedProvider = Provider.family<bool, int>(
  (ref, page) => ref.watch(bookmarksProvider.select((s) => s.contains(page))),
);
