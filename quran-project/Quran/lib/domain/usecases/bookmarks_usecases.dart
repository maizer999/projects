import '../repositories/bookmarks_repository.dart';

class LoadBookmarks {
  const LoadBookmarks(this._repo);
  final BookmarksRepository _repo;
  Set<int> call() => _repo.load();
}

/// Adds or removes a page number; returns the new set.
class TogglePageBookmark {
  const TogglePageBookmark(this._repo);
  final BookmarksRepository _repo;

  Future<Set<int>> call(Set<int> current, int page) async {
    final next = {...current};
    if (!next.add(page)) next.remove(page);
    await _repo.save(next);
    return next;
  }
}
