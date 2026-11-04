import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../../domain/usecases/quran_usecases.dart';
import 'dependency_providers.dart';

final juzIndexProvider = Provider<List<Juz>>((ref) => ref.watch(getJuzIndexProvider)());

final surahsProvider = Provider<List<Surah>>((ref) => ref.watch(getSurahsProvider)());

final pageInfoProvider = Provider.family<PageInfo, int>(
  (ref, page) => ref.watch(getPageInfoProvider)(page),
);
