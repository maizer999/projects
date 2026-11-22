import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/audio_player_data_source.dart';
import 'data/datasources/quran_local_data_source.dart';
import 'data/repositories/quran_repository_impl.dart';
import 'presentation/providers/dependency_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayerDataSource.configureGlobalContext();
  final prefs = await SharedPreferences.getInstance();
  final quranDS = QuranLocalDataSource();
  final quran = QuranRepositoryImpl(quranDS);
  await quran.init(); // bundled Mushaf text, tens of ms

  await NotificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        quranRepositoryProvider.overrideWithValue(quran),
        allMushafAyahsProvider.overrideWithValue(quranDS.ayahs),
      ],
      child: const QuranApp(),
    ),
  );
}
