import 'package:flutter/material.dart';

import '../theme.dart';

/// Rótulo separado do campo por uma margem fixa, em vez do label flutuante
/// padrão do Material (que pode ficar apertado/sobreposto em campos
/// preenchidos). Usado para padronizar o espaçamento em todos os
/// formulários do app.
class CampoRotulado extends StatelessWidget {
  const CampoRotulado({super.key, required this.rotulo, required this.child});

  final String rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
