import 'package:flutter/material.dart';

class AppColors {
  static const bgDark = Color(0xFF0B1020);
  static const bg2Dark = Color(0xFF0F1530);
  static const panelDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const borderDark = Color(0x1AFFFFFF);
  static const textDark = Color(0xFFE9ECF5);
  static const mutedDark = Color(0xFF9AA3BF);

  static const bgLight = Color(0xFFF7F6F1);
  static const bg2Light = Color(0xFFEFECE2);
  static const panelLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE7E3D4);
  static const textLight = Color(0xFF1B1F2A);
  static const mutedLight = Color(0xFF5F6B85);

  static const accent = Color(0xFF8B5CF6);
  static const accent2 = Color(0xFF22D3EE);
  static const gold = Color(0xFFD4AF37);
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
