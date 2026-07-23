import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF07090C);
  static const surface = Color(0xFF0F1316);
  static const surfaceAlt = Color(0xFF151A1D);
  static const border = Color(0xFF1D2326);
  static const accent = Color(0xFF34D399);
  static const accentStrong = Color(0xFF10B981);
  static const negative = Color(0xFFF87171);
  static const textPrimary = Color(0xFFF3F4F6);
  static const textMuted = Color(0xFF9CA3AF);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme = base.colorScheme.copyWith(
    surface: AppColors.background,
    primary: AppColors.accent,
    secondary: AppColors.accent,
    error: AppColors.negative,
    onSurface: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surfaceAlt,
        foregroundColor: AppColors.textMuted,
        selectedBackgroundColor: AppColors.accent,
        selectedForegroundColor: Colors.black,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.accent : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentStrong.withValues(alpha: 0.5)
            : null,
      ),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.surface,
      elevation: 0,
    ),
  );
}
