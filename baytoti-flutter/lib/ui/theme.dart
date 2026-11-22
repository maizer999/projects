import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One color preset. Only the primary/accent change — the warm cream
/// surfaces, text and border colors stay fixed to match the web look.
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
    label: 'أخضر زيتي',
    primary: Color(0xFF2D5A4B),
    primaryDark: Color(0xFF1F4236),
    primarySoft: Color(0xFFE2EEE9),
    accent: Color(0xFFB8A99A),
    accentSoft: Color(0xFFF0EBE6),
  ),
  BaytiPreset(
    id: 'blue',
    label: 'أزرق',
    primary: Color(0xFF1D4ED8),
    primaryDark: Color(0xFF1E3A8A),
    primarySoft: Color(0xFFDBEAFE),
    accent: Color(0xFFB8A99A),
    accentSoft: Color(0xFFF0EBE6),
  ),
  BaytiPreset(
    id: 'purple',
    label: 'بنفسجي',
    primary: Color(0xFF7C3AED),
    primaryDark: Color(0xFF5B21B6),
    primarySoft: Color(0xFFEDE9FE),
    accent: Color(0xFFB8A99A),
    accentSoft: Color(0xFFF0EBE6),
  ),
  BaytiPreset(
    id: 'rose',
    label: 'وردي',
    primary: Color(0xFFBE185D),
    primaryDark: Color(0xFF9D174D),
    primarySoft: Color(0xFFFCE7F3),
    accent: Color(0xFFB8A99A),
    accentSoft: Color(0xFFF0EBE6),
  ),
  BaytiPreset(
    id: 'green',
    label: 'أخضر',
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF14532D),
    primarySoft: Color(0xFFDCFCE7),
    accent: Color(0xFFB8A99A),
    accentSoft: Color(0xFFF0EBE6),
  ),
];

BaytiPreset presetById(String id) =>
    baytiPresets.firstWhere((p) => p.id == id, orElse: () => baytiPresets[0]);

/// Palette — static warm-cream values that never change, plus mutable
/// preset fields used by theme-build (NOT by widget builds — widgets read
/// preset colors from Theme.of(context).colorScheme so they repaint when
/// the user picks a new preset).
class BaytiColors {
  static const Color bg = Color(0xFFF7F4EF);
  static const Color card = Color(0xFFFFFCF9);
  static const Color itemCard = Color(0xFFFAF6F1);
  static const Color itemCardHover = Color(0xFFF2EBE3);

  // Updated by applyPreset — used only when building ThemeData.
  static Color primary = baytiPresets[0].primary;
  static Color primaryDark = baytiPresets[0].primaryDark;
  static Color primarySoft = baytiPresets[0].primarySoft;
  static Color accent = baytiPresets[0].accent;
  static Color accentSoft = baytiPresets[0].accentSoft;

  static const Color text = Color(0xFF2A2724);
  static const Color muted = Color(0xFF7A6E64);
  static const Color mutedSoft = Color(0xFF9A8E82);
  static const Color placeholder = Color(0xFFB8A99A);

  static const Color line = Color(0xFFEDE4D9);
  static const Color lineStrong = Color(0xFFE2D8CA);
  static const Color chipBg = Color(0xFFF0EBE6);
  static const Color chipHover = Color(0xFFE2D9D0);
  static const Color summaryBg = Color(0xFFF0EBE3);
  static const Color summaryBorder = Color(0xFFE3DACD);

  static const Color danger = Color(0xFFC0392B);
  static const Color dangerSoft = Color(0xFFFDE8E6);

  static void applyPreset(BaytiPreset p) {
    primary = p.primary;
    primaryDark = p.primaryDark;
    primarySoft = p.primarySoft;
    accent = p.accent;
    accentSoft = p.accentSoft;
  }
}

/// Reusable soft shadows — three stacked layers for a premium depth feel
/// without any harsh dark edges on the warm cream background.
class BaytiShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}

/// Helper so widgets can read preset colors reactively via Theme.
extension BaytiTheme on BuildContext {
  Color get bPrimary => Theme.of(this).colorScheme.primary;
  Color get bPrimaryDark => Theme.of(this).colorScheme.onPrimaryContainer;
  Color get bPrimarySoft => Theme.of(this).colorScheme.primaryContainer;
  Color get bAccent => Theme.of(this).colorScheme.secondary;
  Color get bAccentSoft => Theme.of(this).colorScheme.secondaryContainer;
}

ThemeData buildBaytiTheme() {
  final preset = BaytiPreset(
    id: 'current',
    label: '',
    primary: BaytiColors.primary,
    primaryDark: BaytiColors.primaryDark,
    primarySoft: BaytiColors.primarySoft,
    accent: BaytiColors.accent,
    accentSoft: BaytiColors.accentSoft,
  );

  final scheme = ColorScheme.light(
    primary: preset.primary,
    onPrimary: Colors.white,
    primaryContainer: preset.primarySoft,
    onPrimaryContainer: preset.primaryDark,
    secondary: preset.accent,
    onSecondary: Colors.white,
    secondaryContainer: preset.accentSoft,
    onSecondaryContainer: BaytiColors.text,
    surface: BaytiColors.card,
    onSurface: BaytiColors.text,
    error: BaytiColors.danger,
    onError: Colors.white,
  );

  // Readex Pro — warm, geometric, excellent Arabic + Latin shaping.
  // Same family the web version uses, so brand stays consistent.
  final base = GoogleFonts.readexProTextTheme().apply(
    bodyColor: BaytiColors.text,
    displayColor: BaytiColors.text,
  );

  // NOTE: no negative letterSpacing — Arabic is cursive and negative tracking
  // breaks the glyph-joining, making words look fragmented or overlapping.
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.55),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.55),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w600),
  );

  final titleStyle = textTheme.titleLarge!.copyWith(fontSize: 20);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BaytiColors.bg,
    canvasColor: BaytiColors.card,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: BaytiColors.bg,
      foregroundColor: BaytiColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: titleStyle.copyWith(color: preset.primaryDark),
      iconTheme: const IconThemeData(color: BaytiColors.text, size: 22),
    ),
    cardTheme: CardThemeData(
      color: BaytiColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: BaytiColors.line, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: preset.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: BaytiColors.lineStrong, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: preset.primaryDark,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BaytiColors.itemCard,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BaytiColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BaytiColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: preset.primary, width: 2),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: BaytiColors.mutedSoft,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: preset.primaryDark,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: BaytiColors.placeholder,
        fontSize: 14,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: preset.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      shape: const CircleBorder(),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BaytiColors.chipBg,
      selectedColor: preset.primary,
      side: BorderSide.none,
      labelStyle: textTheme.labelLarge?.copyWith(
        color: BaytiColors.text,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: const DividerThemeData(
      color: BaytiColors.line,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: BaytiColors.muted,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: BaytiColors.muted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BaytiColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: titleStyle.copyWith(color: preset.primaryDark),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        fontSize: 14.5,
        height: 1.6,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BaytiColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BaytiColors.text,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: BaytiColors.card,
      elevation: 8,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BaytiColors.line),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}