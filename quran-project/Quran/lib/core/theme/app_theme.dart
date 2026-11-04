import 'package:flutter/material.dart';
import 'app_colors.dart';

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
