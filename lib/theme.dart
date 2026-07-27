import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF192134);
  static const surfaceAlt = Color(0xFF232B3E);
  static const border = Color(0xFF232B3E);

  /// Divisor ultra-sutil (`rgba(255,255,255,0.08)`) usado em bordas de card
  /// e separadores de lista — mais discreto que [border].
  static const hairline = Color(0x14FFFFFF);

  /// Azul-confiança — ação primária, navegação selecionada, foco, seleção de
  /// UI. Cor estrutural do produto, não tem relação com valor monetário.
  static const primary = Color(0xFF1E40AF);
  static const primaryStrong = Color(0xFF1E3A8A);

  /// Verde-lucro — reservado exclusivamente para valor monetário positivo e
  /// status "pago". Nunca usado como cor de ação de UI genérica.
  static const accent = Color(0xFF059669);
  static const accentStrong = Color(0xFF047857);

  static const negative = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF94A3B8);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme = base.colorScheme.copyWith(
    surface: AppColors.background,
    primary: AppColors.primary,
    secondary: AppColors.primary,
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
      // Calistoga só no título de tela — dá personalidade de marca onde
      // não há dado numérico. Corpo/formulário/valor continuam em Inter,
      // que tem números tabulares de verdade (Calistoga não).
      titleTextStyle: TextStyle(
        fontFamily: 'Calistoga',
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
    ),
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surfaceAlt,
        foregroundColor: AppColors.textMuted,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: AppColors.textPrimary,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(4),
      radius: const Radius.circular(999),
      thumbColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.15)),
      trackColor: const WidgetStatePropertyAll(Colors.transparent),
      trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      crossAxisMargin: 2,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryStrong.withValues(alpha: 0.5)
            : null,
      ),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.surface,
      elevation: 0,
    ),
  );
}
