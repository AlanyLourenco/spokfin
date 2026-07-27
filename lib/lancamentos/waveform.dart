import 'package:flutter/material.dart';

import '../theme.dart';

class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.niveis});

  /// Valores de 0.0 (silêncio) a 1.0 (volume máximo), do mais antigo ao mais recente.
  final List<double> niveis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final nivel in niveis)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: 4 + nivel * 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
