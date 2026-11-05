import 'package:flutter/material.dart';

/// A full palette the user can pick in Settings. Every surface in both
/// dark and light mode — including the reading page's own card — is
/// recolored to the chosen hue, keeping each color's original
/// lightness/contrast so legibility doesn't change, only the hue. Gold
/// stays gold everywhere (it's ornamental, not a brand color).
class ThemePreset {
  final String id;
  final String label;
  final Color accent;
  final Color accent2;
  final Color bgDark;
  final Color bg2Dark;
  final Color textDark;
  final Color mutedDark;
  final Color pageDark;
  final Color bgLight;
  final Color bg2Light;
  final Color panelLight;
  final Color borderLight;
  final Color textLight;
  final Color mutedLight;
  final Color pageLight;
  const ThemePreset(
    this.id,
    this.label, {
    required this.accent,
    required this.accent2,
    required this.bgDark,
    required this.bg2Dark,
    required this.textDark,
    required this.mutedDark,
    required this.pageDark,
    required this.bgLight,
    required this.bg2Light,
    required this.panelLight,
    required this.borderLight,
    required this.textLight,
    required this.mutedLight,
    required this.pageLight,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    'green',
    'أخضر',
    accent: Color(0xFF1F6B45),
    accent2: Color(0xFF3F9B6A),
    bgDark: Color(0xFF0E2A1E),
    bg2Dark: Color(0xFF15372A),
    textDark: Color(0xFFEFF5F0),
    mutedDark: Color(0xFFA9C2B2),
    pageDark: Color(0xFF1A3B2B),
    bgLight: Color(0xFFC1E1D1),
    bg2Light: Color(0xFFAED5C2),
    panelLight: Color(0xFFEAF1ED),
    borderLight: Color(0xFF8BC1A6),
    textLight: Color(0xFF1F3329),
    mutedLight: Color(0xFF5E7A6C),
    pageLight: Color(0xFFB0DDC7),
  ),
  ThemePreset(
    'blue',
    'أزرق',
    accent: Color(0xFF1F426B),
    accent2: Color(0xFF3F6A9B),
    bgDark: Color(0xFF0E1B2A),
    bg2Dark: Color(0xFF152537),
    textDark: Color(0xFFEFF2F5),
    mutedDark: Color(0xFFA9B5C2),
    pageDark: Color(0xFF1A293B),
    bgLight: Color(0xFFC1D0E1),
    bg2Light: Color(0xFFAEC0D5),
    panelLight: Color(0xFFEAEDF1),
    borderLight: Color(0xFF8BA4C1),
    textLight: Color(0xFF1F2833),
    mutedLight: Color(0xFF5E6B7A),
    pageLight: Color(0xFFB0C5DD),
  ),
  ThemePreset(
    'purple',
    'بنفسجي',
    accent: Color(0xFF421F6B),
    accent2: Color(0xFF6A3F9B),
    bgDark: Color(0xFF1B0E2A),
    bg2Dark: Color(0xFF251537),
    textDark: Color(0xFFF2EFF5),
    mutedDark: Color(0xFFB5A9C2),
    pageDark: Color(0xFF291A3B),
    bgLight: Color(0xFFD0C1E1),
    bg2Light: Color(0xFFC0AED5),
    panelLight: Color(0xFFEDEAF1),
    borderLight: Color(0xFFA48BC1),
    textLight: Color(0xFF281F33),
    mutedLight: Color(0xFF6B5E7A),
    pageLight: Color(0xFFC5B0DD),
  ),
  ThemePreset(
    'maroon',
    'عنّابي',
    accent: Color(0xFF6B1F31),
    accent2: Color(0xFF9B3F54),
    bgDark: Color(0xFF2A0E15),
    bg2Dark: Color(0xFF37151D),
    textDark: Color(0xFFF5EFF0),
    mutedDark: Color(0xFFC2A9AF),
    pageDark: Color(0xFF3B1A22),
    bgLight: Color(0xFFF8E2E7),
    bg2Light: Color(0xFFF0CFD7),
    panelLight: Color(0xFFFFF4F7),
    borderLight: Color(0xFFE3AEBA),
    textLight: Color(0xFF331F24),
    mutedLight: Color(0xFF7A5E65),
    pageLight: Color(0xFFFBDCE3),
  ),
];

ThemePreset presetById(String id) =>
    themePresets.firstWhere((p) => p.id == id, orElse: () => themePresets[0]);

class AppColors {
  // Every one of these is set per the user's chosen preset (see
  // [applyPreset]) — the values below are just the "أخضر" defaults shown
  // before a saved preference loads.
  static Color bgDark = themePresets[0].bgDark;
  static Color bg2Dark = themePresets[0].bg2Dark;
  static const panelDark = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const borderDark = Color(0x1FFFFFFF);
  static Color textDark = themePresets[0].textDark;
  static Color mutedDark = themePresets[0].mutedDark;
  static Color pageDark = themePresets[0].pageDark;

  static Color bgLight = themePresets[0].bgLight;
  static Color bg2Light = themePresets[0].bg2Light;
  static Color panelLight = themePresets[0].panelLight;
  static Color borderLight = themePresets[0].borderLight;
  static Color textLight = themePresets[0].textLight;
  static Color mutedLight = themePresets[0].mutedLight;
  static Color pageLight = themePresets[0].pageLight;

  // Brand accent — mutable so the user's chosen preset (Settings) can
  // repaint every widget that reads it without plumbing a theme object
  // through the whole tree. Always set via [applyPreset].
  static Color accent = themePresets[0].accent;
  static Color accent2 = themePresets[0].accent2;
  static const gold = Color(0xFFC9A646); // ornamental gold (titles, frames)
  static const danger = Color(0xFFEF4444);

  /// End-of-ayah marker (rosette + number) in the reader. A bright aqua that
  /// stands out from both the off-white verse text and every dark preset;
  /// the old gold blended into the text.
  static const ayahMarker = Color(0xFF4DD0E1);

  static void applyPreset(ThemePreset preset) {
    accent = preset.accent;
    accent2 = preset.accent2;
    bgDark = preset.bgDark;
    bg2Dark = preset.bg2Dark;
    textDark = preset.textDark;
    mutedDark = preset.mutedDark;
    pageDark = preset.pageDark;
    bgLight = preset.bgLight;
    bg2Light = preset.bg2Light;
    panelLight = preset.panelLight;
    borderLight = preset.borderLight;
    textLight = preset.textLight;
    mutedLight = preset.mutedLight;
    pageLight = preset.pageLight;
  }
}
