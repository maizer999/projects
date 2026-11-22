import 'surah.dart';

class Juz {
  const Juz({required this.number, required this.startPage, required this.surahs});

  final int number;
  final int startPage;

  /// Surahs that have at least one ayah in this juz.
  final List<Surah> surahs;
}
