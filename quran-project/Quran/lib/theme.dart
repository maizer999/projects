import 'package:flutter/material.dart';

class AppColors {
  // Dark mode — deep forest green, like a lantern-lit mosque at night.
  static const bgDark = Color(0xFF0E2A1E);
  static const bg2Dark = Color(0xFF15372A);
  static const panelDark = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const borderDark = Color(0x1FFFFFFF);
  static const textDark = Color(0xFFEFF5F0);
  static const mutedDark = Color(0xFFA9C2B2);

  // Light mode — warm parchment/cream, like an open mushaf page.
  static const bgLight = Color(0xFFF8F2E2);
  static const bg2Light = Color(0xFFF0E7CF);
  static const panelLight = Color(0xFFFFFCF4);
  static const borderLight = Color(0xFFE3D6AE);
  static const textLight = Color(0xFF26331F);
  static const mutedLight = Color(0xFF6B7A5E);

  // Brand accents.
  static const accent = Color(0xFF1F6B45); // primary green (buttons, play)
  static const accent2 = Color(0xFF3F9B6A); // lighter green (gradients)
  static const gold = Color(0xFFC9A646); // ornamental gold (titles, frames)
  static const danger = Color(0xFFEF4444);
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
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
  );
}
