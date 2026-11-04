import 'package:mushaf_text/mushaf_text.dart' as mt;

/// Offline Mushaf text (KFGQPC Hafs) bundled by the `mushaf_text` package.
class QuranLocalDataSource {
  List<mt.Ayah>? _ayahs;

  /// Loads the bundled text once (~1.4 MB, tens of milliseconds).
  Future<void> init() async {
    _ayahs ??= await mt.Quran.ayahs();
  }

  List<mt.Ayah> get ayahs {
    final a = _ayahs;
    if (a == null) {
      throw StateError('QuranLocalDataSource.init() must be awaited first');
    }
    return a;
  }

  List<mt.Surah> get surahs => mt.Quran.surahs;
}
