import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/utils/arabic_numerals.dart';
import 'package:quran_app/data/datasources/quran_local_data_source.dart';
import 'package:quran_app/data/repositories/quran_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepositoryImpl repo;

  setUpAll(() async {
    repo = QuranRepositoryImpl(QuranLocalDataSource());
    await repo.init();
  });

  test('has 114 surahs and 6236 ayahs', () {
    expect(repo.getSurahs(), hasLength(114));
    expect(repo.getAyahById(6236), isNotNull);
    expect(repo.getAyahById(6237), isNull);
  });

  test('global ayah id matches audio numbering', () {
    final baqarah1 = repo.getSurahAyahs(2).first;
    expect(baqarah1.id, 8); // Al-Fatiha has 7 ayahs
    expect(baqarah1.page, 2);
  });

  test('juz index', () {
    final juz = repo.getJuzIndex();
    expect(juz, hasLength(30));
    expect(juz.first.surahs.map((s) => s.number), [1, 2]);
    expect(juz.last.surahs.first.number, 78);
    expect(juz.last.surahs.last.number, 114);
  });

  test('page info', () {
    expect(repo.getSurahAtPage(1).number, 1);
    expect(repo.getJuzAtPage(604), 30);
  });

  test('arabic digits', () {
    expect(toArabicDigits(604), '٦٠٤');
  });
}
