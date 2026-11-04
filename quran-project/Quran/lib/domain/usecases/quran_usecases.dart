import '../entities/ayah.dart';
import '../entities/juz.dart';
import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetJuzIndex {
  const GetJuzIndex(this._repo);
  final QuranRepository _repo;
  List<Juz> call() => _repo.getJuzIndex();
}

class GetSurahs {
  const GetSurahs(this._repo);
  final QuranRepository _repo;
  List<Surah> call() => _repo.getSurahs();
}

class SearchSurahs {
  const SearchSurahs(this._repo);
  final QuranRepository _repo;

  /// Matches Arabic name, English name (case-insensitive) or exact number.
  List<Surah> call(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _repo
        .getSurahs()
        .where((s) =>
            s.nameArabic.contains(q) ||
            s.nameEnglish.toLowerCase().contains(q) ||
            s.number.toString() == q)
        .toList();
  }
}

class GetSurahAyahs {
  const GetSurahAyahs(this._repo);
  final QuranRepository _repo;
  List<Ayah> call(int surahNumber) => _repo.getSurahAyahs(surahNumber);
}

class GetAyahById {
  const GetAyahById(this._repo);
  final QuranRepository _repo;
  Ayah? call(int id) => _repo.getAyahById(id);
}

/// What the header shows for a page: the first surah on it and its juz.
class PageInfo {
  const PageInfo({required this.page, required this.surah, required this.juz});
  final int page;
  final Surah surah;
  final int juz;
}

class GetPageInfo {
  const GetPageInfo(this._repo);
  final QuranRepository _repo;
  PageInfo call(int page) => PageInfo(
        page: page,
        surah: _repo.getSurahAtPage(page),
        juz: _repo.getJuzAtPage(page),
      );
}
