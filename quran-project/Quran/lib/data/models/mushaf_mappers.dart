import 'package:mushaf_text/mushaf_text.dart' as mt;

import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';

extension MushafSurahMapper on mt.Surah {
  Surah toEntity() => Surah(
        number: number,
        nameArabic: nameArabic,
        nameEnglish: nameEnglish,
        ayahCount: ayahCount,
        startPage: startPage,
        endPage: endPage,
      );
}

extension MushafAyahMapper on mt.Ayah {
  Ayah toEntity() => Ayah(id: id, surah: surah, number: number, juz: juz, page: page);
}
