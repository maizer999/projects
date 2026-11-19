import 'package:flutter/material.dart';

/// One color preset. The user picks one in Settings and the whole app
/// repaints — same pattern as the Quran app.
class BaytiPreset {
  final String id;
  final String label;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;

  const BaytiPreset({
    required this.id,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
  });
}

const List<BaytiPreset> baytiPresets = [
  BaytiPreset(
    id: 'teal',
    label: 'أخضر مزرق',
    primary: Color(0xFF0F766E),
    primaryDark: Color(0xFF0B5A54),
    primarySoft: Color(0xFFCCFBF1),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFEF3C7),
  ),
  BaytiPreset(
    id: 'blue',
    label: 'أزرق',
    primary: Color(0xFF1D4ED8),
    primaryDark: Color(0xFF1E3A8A),
    primarySoft: Color(0xFFDBEAFE),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFEF3C7),
  ),
  BaytiPreset(
    id: 'purple',
    label: 'بنفسجي',
    primary: Color(0xFF7C3AED),
    primaryDark: Color(0xFF5B21B6),
    primarySoft: Color(0xFFEDE9FE),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFEF3C7),
  ),
  BaytiPreset(
    id: 'rose',
    label: 'وردي',
    primary: Color(0xFFBE185D),
    primaryDark: Color(0xFF9D174D),
    primarySoft: Color(0xFFFCE7F3),
    accent: Color(0xFF0EA5E9),
    accentSoft: Color(0xFFE0F2FE),
  ),
  BaytiPreset(
    id: 'green',
    label: 'أخضر',
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF14532D),
    primarySoft: Color(0xFFDCFCE7),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFEF3C7),
  ),
];

BaytiPreset presetById(String id) =>
    baytiPresets.firstWhere((p) => p.id == id, orElse: () => baytiPresets[0]);

/// Mutable palette — every widget reads from these, and
/// [applyPreset] rewrites them when the user picks a new preset. Same
/// trick as the Quran app's AppColors so we don't have to thread a
/// theme object through every widget.
class BaytiColors {
  static Color bg = const Color(0xFFF6F7FB);
  static Color card = Colors.white;
  static Color primary = baytiPresets[0].primary;
  static Color primaryDark = baytiPresets[0].primaryDark;
  static Color primarySoft = baytiPresets[0].primarySoft;
  static Color accent = baytiPresets[0].accent;
  static Color accentSoft = baytiPresets[0].accentSoft;
  static Color text = const Color(0xFF0F172A);
  static Color muted = const Color(0xFF64748B);
  static Color line = const Color(0xFFE2E8F0);
  static Color danger = const Color(0xFFDC2626);
  static Color dangerSoft = const Color(0xFFFEE2E2);
  static Color success = const Color(0xFF10B981);

  static void applyPreset(BaytiPreset p) {
    primary = p.primary;
    primaryDark = p.primaryDark;
    primarySoft = p.primarySoft;
    accent = p.accent;
    accentSoft = p.accentSoft;
  }
}

ThemeData buildBaytiTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BaytiColors.primary,
    primary: BaytiColors.primary,
    secondary: BaytiColors.accent,
    surface: BaytiColors.card,
    error: BaytiColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    fontFamily: 'SF Arabic',
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: BaytiColors.text,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: BaytiColors.text,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: BaytiColors.text,
      ),
      bodyLarge: TextStyle(color: BaytiColors.text),
      bodyMedium: TextStyle(color: BaytiColors.text),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: BaytiColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: BaytiColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.55),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BaytiColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BaytiColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: BaytiColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BaytiColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.75),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: BaytiColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: BaytiColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: BaytiColors.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: BaytiColors.muted),
      hintStyle: TextStyle(color: BaytiColors.muted),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: BaytiColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: BaytiColors.primary,
      side: BorderSide(color: BaytiColors.line),
      labelStyle: TextStyle(
        color: BaytiColors.text,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: BaytiColors.primarySoft.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? BaytiColors.primaryDark
              : BaytiColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? BaytiColors.primaryDark
              : BaytiColors.muted,
        ),
      ),
      elevation: 0,
      height: 68,
    ),
    dividerTheme: DividerThemeData(
      color: BaytiColors.line,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: BaytiColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: TextStyle(
        color: BaytiColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BaytiColors.text,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
