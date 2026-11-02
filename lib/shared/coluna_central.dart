import 'package:flutter/material.dart';

/// Limita o conteúdo a uma coluna estreita centralizada, como a moldura de
/// celular do protótipo (spec `0012`).
///
/// Sem isso, numa tela de 1366px a linha de lançamento fica com um vão enorme
/// entre a descrição e o valor — o olho perde a associação entre os dois.
///
/// Aplicado **uma vez**, no `builder:` do `MaterialApp` em `main.dart`: cobre
/// todas as telas de uma vez, inclusive as que forem criadas depois. Não
/// envolva `Scaffold` de tela com este widget — seria duplicar o limite.
class ColunaCentral extends StatelessWidget {
  const ColunaCentral({
    super.key,
    required this.child,
    this.larguraMaxima = 460,
  });

  final Widget child;
  final double larguraMaxima;

  @override
  Widget build(BuildContext context) {
    return Align(
      // topCenter, não center: centralizar na vertical faria uma tela curta
      // flutuar no meio do vazio.
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: child,
      ),
    );
  }
}
