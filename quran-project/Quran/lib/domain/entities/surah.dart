class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.ayahCount,
    required this.startPage,
    required this.endPage,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int ayahCount;
  final int startPage;
  final int endPage;
}
