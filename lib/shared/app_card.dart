import 'package:flutter/material.dart';

import '../theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.hairline),
      ),
      child: child,
    );
  }
}

/// Rótulo pequeno em caixa alta (ex: "CATEGORIA", "FATURAMENTO") usado como
/// cabeçalho de seção dentro de um [AppCard] — mesmo estilo em todo o app.
class RotuloCard extends StatelessWidget {
  const RotuloCard(this.texto, {super.key, this.letterSpacing, this.negrito = false});

  final String texto;
  final double? letterSpacing;
  final bool negrito;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        letterSpacing: letterSpacing,
        fontWeight: negrito ? FontWeight.bold : null,
      ),
    );
  }
}
