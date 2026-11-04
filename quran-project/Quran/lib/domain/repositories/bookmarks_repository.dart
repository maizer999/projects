/// Mushaf pages the user bookmarked (المرجعية), stored as a sorted set
/// of page numbers in the range 1..604.
abstract interface class BookmarksRepository {
  Set<int> load();
  Future<void> save(Set<int> pages);
}