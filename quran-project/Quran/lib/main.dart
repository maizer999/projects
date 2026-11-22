import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/datasources/audio_player_data_source.dart';
import 'data/datasources/quran_local_data_source.dart';
import 'data/repositories/quran_repository_impl.dart';
import 'presentation/providers/dependency_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayerDataSource.configureGlobalContext();
  final prefs = await SharedPreferences.getInstance();
  final quran = QuranRepositoryImpl(QuranLocalDataSource());
  await quran.init(); // bundled Mushaf text, tens of ms

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        quranRepositoryProvider.overrideWithValue(quran),
      ],
      child: const QuranApp(),
    ),
  );
}
