import 'package:flutter/animation.dart';

/// Vocabulário único de motion do app: toda animação nova usa uma duração e
/// uma curva daqui, em vez de cada tela inventar seu próprio valor solto.
/// Curvas customizadas (não [Curves.easeInOut]/default do Material) seguem os
/// princípios de easing com intenção de Emil Kowalski — desacelera rápido na
/// entrada, acelera rápido na saída, nunca linear.
class AppMotion {
  AppMotion._();

  static const rapido = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const lento = Duration(milliseconds: 300);

  /// Ease-out expo: parte rápido, desacelera suavemente até o repouso.
  /// Usada em qualquer elemento que aparece/entra (modal, card, item de lista).
  static const entrada = Cubic(0.16, 1, 0.3, 1);

  /// Ease-in expo: acelera rápido para sair de cena.
  /// Usada em qualquer elemento que desaparece/sai (modal fechando, dismiss).
  static const saida = Cubic(0.7, 0, 0.84, 0);
}
