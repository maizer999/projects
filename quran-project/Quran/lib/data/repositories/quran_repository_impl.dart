import '../../core/constants/app_constants.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';
import '../models/mushaf_mappers.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._local);
  final QuranLocalDataSource _local;

  late final List<Surah> _surahs;
  late final List<Ayah> _ayahs; // index = id - 1
  late final Map<int, List<Ayah>> _bySurah;
  late final List<Ayah> _firstAyahOfPage; // index = page - 1
  late final List<Juz> _juzIndex;
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    await _local.init();
    _surahs = _local.surahs.map((s) => s.toEntity()).toList(growable: false);
    _ayahs = _local.ayahs.map((a) => a.toEntity()).toList(growable: false);

    _bySurah = <int, List<Ayah>>{};
    final firstOfPage = List<Ayah?>.filled(AppConstants.totalPages, null);
    for (final a in _ayahs) {
      _bySurah.putIfAbsent(a.surah, () => <Ayah>[]).add(a);
      firstOfPage[a.page - 1] ??= a;
    }
    _firstAyahOfPage = firstOfPage.map((a) => a!).toList(growable: false);
    _juzIndex = _buildJuzIndex();
    _ready = true;
  }

  List<Juz> _buildJuzIndex() {
    final result = <Juz>[];
    for (var n = 1; n <= AppConstants.totalJuz; n++) {
      final inJuz = _ayahs.where((a) => a.juz == n);
      final surahNumbers = <int>{for (final a in inJuz) a.surah};
      result.add(Juz(
        number: n,
        startPage: inJuz.first.page,
        surahs: [for (final s in surahNumbers) getSurah(s)],
      ));
    }
    return List.unmodifiable(result);
  }

  int _clampPage(int page) => page.clamp(AppConstants.firstPage, AppConstants.totalPages);

  @override
  List<Surah> getSurahs() => _surahs;

  @override
  Surah getSurah(int number) => _surahs[number - 1];

  @override
  Surah getSurahAtPage(int page) => getSurah(_firstAyahOfPage[_clampPage(page) - 1].surah);

  @override
  int getJuzAtPage(int page) => _firstAyahOfPage[_clampPage(page) - 1].juz;

  @override
  List<Ayah> getSurahAyahs(int surahNumber) => _bySurah[surahNumber] ?? const [];

  @override
  Ayah? getAyahById(int id) => (id >= 1 && id <= _ayahs.length) ? _ayahs[id - 1] : null;

  @override
  List<Juz> getJuzIndex() => _juzIndex;
}
