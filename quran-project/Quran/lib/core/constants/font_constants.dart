/// Arabic fonts the user can choose for the reading text.
///
/// Only fonts that keep the Madinah Mushaf look AND cover every mark in the
/// Uthmani text are listed — a font that lacks a mark makes the system draw
/// that mark in another font, which looks mixed. (KFGQPC Uthman Taha Naskh
/// was checked and left out: it lacks 23 Quranic marks, e.g. alif wasla and
/// the stop signs.)
class ArabicFontOption {
  const ArabicFontOption({
    required this.id,
    required this.label,
    required this.family,
    required this.ayahEnd,
    this.package,
  });

  final String id;
  final String label;
  final String family;

  /// Set for fonts that ship inside a dependency.
  final String? package;

  /// Text placed before the Arabic-Indic ayah number. Each font draws its
  /// own end-of-ayah ornament from this, so the number stays in the same
  /// font as the verse.
  final String ayahEnd;
}

const String kDefaultFontId = 'kfgqpc';

const List<ArabicFontOption> arabicFonts = [
  // Official King Fahd Complex font (bundled by mushaf_text). Its data
  // writes the number as NBSP + digits and the font draws the rosette.
  ArabicFontOption(
    id: 'kfgqpc',
    label: 'مصحف المدينة (مجمع الملك فهد)',
    family: 'MushafHafs',
    package: 'mushaf_text',
    ayahEnd: '\u00A0',
  ),
  // Amiri's Quran variant (SIL OFL). U+06DD + digits = enclosed ayah number.
  ArabicFontOption(
    id: 'amiri_quran',
    label: 'أميري للقرآن',
    family: 'AmiriQuran',
    ayahEnd: '\u06DD',
  ),
];

ArabicFontOption arabicFontById(String id) =>
    arabicFonts.firstWhere((f) => f.id == id, orElse: () => arabicFonts.first);
