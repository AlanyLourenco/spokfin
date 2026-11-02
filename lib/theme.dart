import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF04090D);

  /// Superfície de card — e também de campo de formulário, que precisa de um
  /// degrau visível sobre o fundo quase preto (ver spec 0012, decisão D2).
  static const surface = Color(0xFF0D1520);

  /// Superfície rebaixada, mais escura que [surface]: área afundada **dentro**
  /// de um card (fundo de gráfico, mini-stat). Nunca use em campo de
  /// formulário sobre o fundo — some.
  static const surfaceSunken = Color(0xFF0A1119);

  /// Borda sólida de card e de contêiner.
  static const border = Color(0xFF1B2533);

  /// Divisor ultra-sutil (`rgba(255,255,255,0.08)`) para separar linha de
  /// lista — mais discreto que [border], que fecha o card por fora.
  static const hairline = Color(0x14FFFFFF);

  /// Azul-confiança — ação primária, navegação selecionada, foco, seleção de
  /// UI. Cor estrutural do produto, não tem relação com valor monetário.
  static const primary = Color(0xFF2563EB);
  static const primaryStrong = Color(0xFF1D4ED8);

  /// Verde-lucro — reservado exclusivamente para valor monetário positivo e
  /// status "pago". Nunca usado como cor de ação de UI genérica.
  static const accent = Color(0xFF4ADE80);
  static const accentStrong = Color(0xFF22C55E);

  /// Coral — saída de dinheiro e erro.
  static const negative = Color(0xFFFB7185);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textMuted = Color(0xFF6B7A8F);
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
      // Inter em tudo, como o protótipo (spec 0012, decisão D3). A Calistoga
      // continua carregada no web/index.html — voltar é trocar esta linha.
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
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
      fillColor: AppColors.surface,
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
        backgroundColor: AppColors.surface,
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
