import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/audio_player_data_source.dart';
import '../../data/datasources/preferences_data_source.dart';
import '../../data/repositories/audio_repository_impl.dart';
import '../../data/repositories/mistakes_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/mistakes_repository.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/mistakes_usecases.dart';
import '../../domain/usecases/quran_usecases.dart';
import '../../domain/usecases/settings_usecases.dart';

// ---------------------------------------------------------------------------
// Overridden in main() once their async setup has finished.
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

/// Already initialised (text loaded) when injected.
final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => throw UnimplementedError('Override quranRepositoryProvider in main()'),
);

// ---------------------------------------------------------------------------
// Data sources & repositories
// ---------------------------------------------------------------------------

final preferencesDataSourceProvider = Provider<PreferencesDataSource>(
  (ref) => PreferencesDataSource(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(preferencesDataSourceProvider)),
);

final mistakesRepositoryProvider = Provider<MistakesRepository>(
  (ref) => MistakesRepositoryImpl(ref.watch(preferencesDataSourceProvider)),
);

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final repo = AudioRepositoryImpl(AudioPlayerDataSource());
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Use cases
// ---------------------------------------------------------------------------

final getJuzIndexProvider = Provider((ref) => GetJuzIndex(ref.watch(quranRepositoryProvider)));
final getSurahsProvider = Provider((ref) => GetSurahs(ref.watch(quranRepositoryProvider)));
final searchSurahsProvider = Provider((ref) => SearchSurahs(ref.watch(quranRepositoryProvider)));
final getSurahAyahsProvider = Provider((ref) => GetSurahAyahs(ref.watch(quranRepositoryProvider)));
final getAyahByIdProvider = Provider((ref) => GetAyahById(ref.watch(quranRepositoryProvider)));
final getPageInfoProvider = Provider((ref) => GetPageInfo(ref.watch(quranRepositoryProvider)));

final loadSettingsProvider = Provider((ref) => LoadSettings(ref.watch(settingsRepositoryProvider)));
final saveSettingsProvider = Provider((ref) => SaveSettings(ref.watch(settingsRepositoryProvider)));
final getRecitersProvider = Provider((ref) => GetReciters(ref.watch(settingsRepositoryProvider)));
final loadReadingPositionProvider =
    Provider((ref) => LoadReadingPosition(ref.watch(settingsRepositoryProvider)));
final saveReadingPositionProvider =
    Provider((ref) => SaveReadingPosition(ref.watch(settingsRepositoryProvider)));

final loadMistakesProvider = Provider((ref) => LoadMistakes(ref.watch(mistakesRepositoryProvider)));
final toggleAyahMistakeProvider =
    Provider((ref) => ToggleAyahMistake(ref.watch(mistakesRepositoryProvider)));
final resetSurahMistakesProvider =
    Provider((ref) => ResetSurahMistakes(ref.watch(mistakesRepositoryProvider)));
