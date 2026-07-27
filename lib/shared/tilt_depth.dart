import 'package:flutter/material.dart';

import 'motion.dart';

/// Envolve [child] com profundidade 3D real (`Matrix4` com perspectiva) —
/// inclina sutilmente em resposta ao hover do mouse (web/desktop) ou ao
/// toque (mobile), voltando ao neutro com o motion padrão do app ao sair ou
/// soltar. Sem pacote novo: só `Transform`/`Matrix4` do Flutter.
///
/// Uso restrito a elementos com afordance de interação real (card clicável,
/// botão principal) — nunca em texto estático nem em todos os cards de uma
/// tela ao mesmo tempo (ver `specs/0008-unificacao-visual-motion/design.md`).
class TiltDepth extends StatefulWidget {
  const TiltDepth({super.key, required this.child, this.maxAngle = 0.05});

  final Widget child;

  /// Ângulo máximo de rotação (radianos) em cada eixo no pico do efeito.
  final double maxAngle;

  @override
  State<TiltDepth> createState() => _TiltDepthState();
}

class _TiltDepthState extends State<TiltDepth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  Offset _pivot = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.base,
      reverseDuration: AppMotion.lento,
    );
    _t = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.entrada,
      reverseCurve: AppMotion.saida,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _atualizar(Offset local) {
    // Tilt é profundidade decorativa, não informação de estado — com motion
    // reduzido pedido pelo usuário, o certo é desligar completamente, não
    // só suavizar (ao contrário de opacidade/estado, que devem continuar).
    if (MediaQuery.of(context).disableAnimations) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || box.size.width == 0 || box.size.height == 0) return;
    final dx = (local.dx / box.size.width) * 2 - 1;
    final dy = (local.dy / box.size.height) * 2 - 1;
    setState(() {
      _pivot = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1));
    });
    _controller.forward();
  }

  void _neutralizar() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Listener (não GestureDetector) porque não pode competir pelo gesto de
    // toque com o child interativo (ex: FloatingActionButton.onPressed) —
    // Listener só observa o ponteiro bruto, nunca reivindica a gesture arena.
    return MouseRegion(
      onHover: (event) => _atualizar(event.localPosition),
      onExit: (_) => _neutralizar(),
      child: Listener(
        onPointerDown: (event) => _atualizar(event.localPosition),
        onPointerMove: (event) => _atualizar(event.localPosition),
        onPointerUp: (_) => _neutralizar(),
        onPointerCancel: (_) => _neutralizar(),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, child) {
            final intensidade = _t.value;
            final rotateY = _pivot.dx * widget.maxAngle * intensidade;
            final rotateX = -_pivot.dy * widget.maxAngle * intensidade;
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(rotateX)
              ..rotateY(rotateY);
            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
