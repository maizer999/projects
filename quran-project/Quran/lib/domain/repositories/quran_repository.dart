import '../entities/ayah.dart';
import '../entities/juz.dart';
import '../entities/surah.dart';

/// Read access to the Mushaf text and its structure.
/// Implementations must be initialised (see [init]) before the sync getters
/// are used.
abstract interface class QuranRepository {
  Future<void> init();

  List<Surah> getSurahs();
  Surah getSurah(int number);

  /// The first surah printed on [page].
  Surah getSurahAtPage(int page);

  List<Ayah> getSurahAyahs(int surahNumber);
  Ayah? getAyahById(int id);

  /// Juz number shown at the top of [page].
  int getJuzAtPage(int page);

  List<Juz> getJuzIndex();
}
