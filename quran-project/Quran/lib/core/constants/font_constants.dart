/// Arabic fonts the user can choose for the reading text.
///
/// [package] is set for fonts that ship inside a dependency (the Madinah
/// KFGQPC font is bundled by `mushaf_text`); the others are declared in
/// pubspec.yaml and need no package.
class ArabicFontOption {
  const ArabicFontOption({
    required this.id,
    required this.label,
    required this.family,
    this.package,
  });

  final String id;
  final String label;
  final String family;
  final String? package;
}

const String kDefaultFontId = 'kfgqpc';

const List<ArabicFontOption> arabicFonts = [
  ArabicFontOption(
    id: 'kfgqpc',
    label: 'مصحف المدينة (KFGQPC)',
    family: 'MushafHafs',
    package: 'mushaf_text',
  ),
  ArabicFontOption(id: 'amiri', label: 'Amiri', family: 'Amiri'),
  ArabicFontOption(
    id: 'scheherazade',
    label: 'Scheherazade New',
    family: 'ScheherazadeNew',
  ),
];

ArabicFontOption arabicFontById(String id) =>
    arabicFonts.firstWhere((f) => f.id == id, orElse: () => arabicFonts.first);
