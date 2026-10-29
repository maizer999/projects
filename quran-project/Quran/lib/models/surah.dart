class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        number: j['number'] as int,
        name: j['name'] as String,
        englishName: j['englishName'] as String,
        englishNameTranslation: j['englishNameTranslation'] as String,
        numberOfAyahs: j['numberOfAyahs'] as int,
        revelationType: j['revelationType'] as String,
      );
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        number: j['number'] as int,
        numberInSurah: j['numberInSurah'] as int,
        text: j['text'] as String,
      );
}

class PageAyah {
  final int globalNumber;
  final int numberInSurah;
  final String text;
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;
  final int surahNumberOfAyahs;

  const PageAyah({
    required this.globalNumber,
    required this.numberInSurah,
    required this.text,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.surahNumberOfAyahs,
  });

  factory PageAyah.fromJson(Map<String, dynamic> j) {
    final surah = j['surah'] as Map<String, dynamic>;
    return PageAyah(
      globalNumber: j['number'] as int,
      numberInSurah: j['numberInSurah'] as int,
      text: j['text'] as String,
      surahNumber: surah['number'] as int,
      surahName: surah['name'] as String,
      surahEnglishName: surah['englishName'] as String,
      surahNumberOfAyahs: surah['numberOfAyahs'] as int,
    );
  }
}

class QuranPage {
  final int number;
  final List<PageAyah> ayahs;

  const QuranPage({required this.number, required this.ayahs});

  factory QuranPage.fromJson(Map<String, dynamic> j) => QuranPage(
        number: j['number'] as int,
        ayahs: (j['ayahs'] as List)
            .map((a) => PageAyah.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final List<Ayah> ayahs;

  const SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.ayahs,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> j) => SurahDetail(
        number: j['number'] as int,
        name: j['name'] as String,
        englishName: j['englishName'] as String,
        englishNameTranslation: j['englishNameTranslation'] as String,
        numberOfAyahs: j['numberOfAyahs'] as int,
        revelationType: j['revelationType'] as String,
        ayahs: (j['ayahs'] as List)
            .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}
