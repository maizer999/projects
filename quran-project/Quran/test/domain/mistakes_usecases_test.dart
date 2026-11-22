import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/data/datasources/preferences_data_source.dart';
import 'package:quran_app/data/repositories/mistakes_repository_impl.dart';
import 'package:quran_app/domain/usecases/mistakes_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MistakesRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = MistakesRepositoryImpl(PreferencesDataSource(await SharedPreferences.getInstance()));
  });

  test('toggle marks, then unmarks, and persists', () async {
    final toggle = ToggleAyahMistake(repo);

    final first = await toggle(const {}, surah: 2, ayahNumber: 5);
    expect(first.marked, isTrue);
    expect(repo.load(), {2: {5}});

    final second = await toggle(first.mistakes, surah: 2, ayahNumber: 5);
    expect(second.marked, isFalse);
    expect(repo.load(), isEmpty);
  });

  test('reset clears only that surah', () async {
    final toggle = ToggleAyahMistake(repo);
    var m = (await toggle(const {}, surah: 1, ayahNumber: 1)).mistakes;
    m = (await toggle(m, surah: 2, ayahNumber: 3)).mistakes;

    final after = await ResetSurahMistakes(repo)(m, 1);
    expect(after, {2: {3}});
    expect(repo.load(), {2: {3}});
  });

  test('reads the legacy saved format', () async {
    SharedPreferences.setMockInitialValues({'surahMistakeAyahs': '{"18":[1,10]}'});
    final legacy =
        MistakesRepositoryImpl(PreferencesDataSource(await SharedPreferences.getInstance()));
    expect(legacy.load(), {18: {1, 10}});
  });
}
