class Ayah {
  const Ayah({
    required this.id,
    required this.surah,
    required this.number,
    required this.juz,
    required this.page,
    required this.text,
  });

  /// Global id 1..6236 in mushaf order (also the audio file number).
  final int id;
  final int surah;

  /// Number inside its surah.
  final int number;
  final int juz;
  final int page;

  /// The verse text without its number (number is drawn by the reader).
  final String text;
}
