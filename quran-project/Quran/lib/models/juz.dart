/// A Juz (جزء) — one of the Quran's 30 standard equal parts.
///
/// Boundaries are fixed by the standard Mushaf division and never change,
/// so this is hard-coded data rather than something fetched from an API.
class Juz {
  final int number; // 1..30
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  const Juz({
    required this.number,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  /// Whether [surahNumber] has any ayahs that fall inside this Juz
  /// (including a surah that only partially overlaps at the edges).
  bool containsSurah(int surahNumber) =>
      surahNumber >= startSurah && surahNumber <= endSurah;
}

/// The 30 Juz of the standard Mushaf, with their start/end surah:ayah.
const List<Juz> quranJuzs = [
  Juz(number: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141),
  Juz(number: 2, startSurah: 2, startAyah: 142, endSurah: 2, endAyah: 252),
  Juz(number: 3, startSurah: 2, startAyah: 253, endSurah: 3, endAyah: 92),
  Juz(number: 4, startSurah: 3, startAyah: 93, endSurah: 4, endAyah: 23),
  Juz(number: 5, startSurah: 4, startAyah: 24, endSurah: 4, endAyah: 147),
  Juz(number: 6, startSurah: 4, startAyah: 148, endSurah: 5, endAyah: 81),
  Juz(number: 7, startSurah: 5, startAyah: 82, endSurah: 6, endAyah: 110),
  Juz(number: 8, startSurah: 6, startAyah: 111, endSurah: 7, endAyah: 87),
  Juz(number: 9, startSurah: 7, startAyah: 88, endSurah: 8, endAyah: 40),
  Juz(number: 10, startSurah: 8, startAyah: 41, endSurah: 9, endAyah: 92),
  Juz(number: 11, startSurah: 9, startAyah: 93, endSurah: 11, endAyah: 5),
  Juz(number: 12, startSurah: 11, startAyah: 6, endSurah: 12, endAyah: 52),
  Juz(number: 13, startSurah: 12, startAyah: 53, endSurah: 14, endAyah: 52),
  Juz(number: 14, startSurah: 15, startAyah: 1, endSurah: 16, endAyah: 128),
  Juz(number: 15, startSurah: 17, startAyah: 1, endSurah: 18, endAyah: 74),
  Juz(number: 16, startSurah: 18, startAyah: 75, endSurah: 20, endAyah: 135),
  Juz(number: 17, startSurah: 21, startAyah: 1, endSurah: 22, endAyah: 78),
  Juz(number: 18, startSurah: 23, startAyah: 1, endSurah: 25, endAyah: 20),
  Juz(number: 19, startSurah: 25, startAyah: 21, endSurah: 27, endAyah: 55),
  Juz(number: 20, startSurah: 27, startAyah: 56, endSurah: 29, endAyah: 45),
  Juz(number: 21, startSurah: 29, startAyah: 46, endSurah: 33, endAyah: 30),
  Juz(number: 22, startSurah: 33, startAyah: 31, endSurah: 36, endAyah: 27),
  Juz(number: 23, startSurah: 36, startAyah: 28, endSurah: 39, endAyah: 31),
  Juz(number: 24, startSurah: 39, startAyah: 32, endSurah: 41, endAyah: 46),
  Juz(number: 25, startSurah: 41, startAyah: 47, endSurah: 45, endAyah: 37),
  Juz(number: 26, startSurah: 46, startAyah: 1, endSurah: 51, endAyah: 30),
  Juz(number: 27, startSurah: 51, startAyah: 31, endSurah: 57, endAyah: 29),
  Juz(number: 28, startSurah: 58, startAyah: 1, endSurah: 66, endAyah: 12),
  Juz(number: 29, startSurah: 67, startAyah: 1, endSurah: 77, endAyah: 50),
  Juz(number: 30, startSurah: 78, startAyah: 1, endSurah: 114, endAyah: 6),
];
