import 'package:flutter/material.dart';

/// A full palette the user can pick in Settings. Dark mode (the app's
/// chrome — toolbar, surah list, settings) is recolored entirely to the
/// chosen hue. Light mode and the reading page itself stay warm
/// cream/parchment on purpose (that's the "paper" the mushaf is printed
/// on, not a brand color), and gold stays gold everywhere.
class ThemePreset {
  final String id;
  final String label;
  final Color accent;
  final Color accent2;
  final Color bgDark;
  final Color bg2Dark;
  final Color textDark;
  final Color mutedDark;
  const ThemePreset(
    this.id,
    this.label, {
    required this.accent,
    required this.accent2,
    required this.bgDark,
    required this.bg2Dark,
    required this.textDark,
    required this.mutedDark,
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
  ),
];

ThemePreset presetById(String id) =>
    themePresets.firstWhere((p) => p.id == id, orElse: () => themePresets[0]);

class AppColors {
  // Dark mode — set per the user's chosen preset (see [applyPreset]);
  // these defaults are the "أخضر" preset.
  static Color bgDark = themePresets[0].bgDark;
  static Color bg2Dark = themePresets[0].bg2Dark;
  static const panelDark = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const borderDark = Color(0x1FFFFFFF);
  static Color textDark = themePresets[0].textDark;
  static Color mutedDark = themePresets[0].mutedDark;

  // Light mode — always warm parchment/cream, like an open mushaf page.
  static const bgLight = Color(0xFFF8F2E2);
  static const bg2Light = Color(0xFFF0E7CF);
  static const panelLight = Color(0xFFFFFCF4);
  static const borderLight = Color(0xFFE3D6AE);
  static const textLight = Color(0xFF26331F);
  static const mutedLight = Color(0xFF6B7A5E);

  // Brand accent — mutable so the user's chosen preset (Settings) can
  // repaint every widget that reads it without plumbing a theme object
  // through the whole tree. Always set via [applyPreset].
  static Color accent = themePresets[0].accent;
  static Color accent2 = themePresets[0].accent2;
  static const gold = Color(0xFFC9A646); // ornamental gold (titles, frames)
  static const danger = Color(0xFFEF4444);

  static void applyPreset(ThemePreset preset) {
    accent = preset.accent;
    accent2 = preset.accent2;
    bgDark = preset.bgDark;
    bg2Dark = preset.bg2Dark;
    textDark = preset.textDark;
    mutedDark = preset.mutedDark;
  }
}

ThemeData buildTheme({required bool dark}) {
  final colors = dark
      ? ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent2,
          surface: AppColors.bg2Dark,
          onSurface: AppColors.textDark,
        )
      : ColorScheme.light(
          primary: AppColors.accent,
          secondary: AppColors.accent2,
          surface: AppColors.panelLight,
          onSurface: AppColors.textLight,
        );

  final bg = dark ? AppColors.bgDark : AppColors.bgLight;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: colors,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: Typography.englishLike2021.apply(
      bodyColor: dark ? AppColors.textDark : AppColors.textLight,
      displayColor: dark ? AppColors.textDark : AppColors.textLight,
    ),
    dividerColor: dark ? AppColors.borderDark : AppColors.borderLight,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.bg2Dark : AppColors.panelLight,
      foregroundColor: dark ? AppColors.textDark : AppColors.textLight,
      elevation: 0,
    ),
    cardColor: dark ? AppColors.bg2Dark : AppColors.panelLight,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.bg2Dark : AppColors.panelLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
  );
}
