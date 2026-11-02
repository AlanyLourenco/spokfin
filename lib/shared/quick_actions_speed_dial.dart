import 'package:flutter/material.dart';

import '../lancamentos/anotar_screen.dart';
import '../lancamentos/falar_screen.dart';
import '../lancamentos/ia_service.dart';
import '../lancamentos/revisar_lancamento_screen.dart';
import '../theme.dart';
import 'motion.dart';
import 'tilt_depth.dart';

class QuickActionsSpeedDial extends StatefulWidget {
  const QuickActionsSpeedDial({
    super.key,
    required this.empresaId,
    this.onConcluido,
  });

  final String empresaId;
  final VoidCallback? onConcluido;

  @override
  State<QuickActionsSpeedDial> createState() => _QuickActionsSpeedDialState();
}

class _QuickActionsSpeedDialState extends State<QuickActionsSpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _aberto = false;

  @override
  void initState() {
    super.initState();
    // Abrir é deliberado (o usuário decide agir); fechar é resposta do
    // sistema a uma escolha já feita — por isso a saída é mais rápida que
    // a entrada (timing assimétrico).
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.base,
      reverseDuration: AppMotion.rapido,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alternar() {
    setState(() => _aberto = !_aberto);
    if (MediaQuery.of(context).disableAnimations) {
      // Opacidade/estado continuam (os itens aparecem), só o deslocamento
      // animado é removido — reduzido, não zero, como pede review-animations.
      _controller.value = _aberto ? 1 : 0;
      return;
    }
    if (_aberto) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _fechar() {
    if (!_aberto) return;
    setState(() => _aberto = false);
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 0;
      return;
    }
    _controller.reverse();
  }

  Future<void> _abrirFalar() async {
    _fechar();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FalarScreen(empresaId: widget.empresaId),
      ),
    );
    widget.onConcluido?.call();
  }

  Future<void> _abrirAnotar() async {
    _fechar();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnotarScreen(empresaId: widget.empresaId),
      ),
    );
    widget.onConcluido?.call();
  }

  Future<void> _abrirManual() async {
    _fechar();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RevisarLancamentoScreen(
          empresaId: widget.empresaId,
          lancamento: LancamentoExtraido(
            tipo: 'entrada',
            valor: 0,
            descricao: '',
            categoria: '',
            status: 'pago',
            querNotaFiscal: false,
          ),
        ),
      ),
    );
    widget.onConcluido?.call();
  }

  /// Cada item começa em [inicio] (0-1) e termina em 1, criando o efeito de
  /// stagger — o item mais perto do FAB abre primeiro na entrada.
  Animation<double> _staggered(double inicio) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(inicio, 1, curve: AppMotion.entrada),
      reverseCurve: Interval(0, 1 - inicio, curve: AppMotion.saida),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tFalar = _staggered(0);
    final tAnotar = _staggered(0.12);
    final tManual = _staggered(0.24);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final visivel = _controller.value > 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (visivel) ...[
              _ItemAcaoAnimado(
                animation: tManual,
                label: 'Manual',
                icon: Icons.add,
                onTap: _abrirManual,
              ),
              const SizedBox(height: 10),
              _ItemAcaoAnimado(
                animation: tAnotar,
                label: 'Anotar',
                icon: Icons.edit_note,
                onTap: _abrirAnotar,
              ),
              const SizedBox(height: 10),
              _ItemAcaoAnimado(
                animation: tFalar,
                label: 'Falar',
                icon: Icons.mic,
                onTap: _abrirFalar,
                destaque: true,
              ),
              const SizedBox(height: 14),
            ],
            TiltDepth(
              maxAngle: 0.09,
              child: FloatingActionButton(
                heroTag: 'quick_actions_toggle',
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                onPressed: _alternar,
                child: AnimatedRotation(
                  turns: _aberto ? 0.125 : 0,
                  duration: AppMotion.base,
                  curve: AppMotion.entrada,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Envolve [_ItemAcao] com a entrada em stagger: opacidade 0→1 e leve
/// deslocamento/escala a partir de perto do repouso (nunca `scale(0)`).
class _ItemAcaoAnimado extends StatelessWidget {
  const _ItemAcaoAnimado({
    required this.animation,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destaque = false,
  });

  final Animation<double> animation;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: Transform.scale(
              scale: 0.95 + 0.05 * t,
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        );
      },
      child: _ItemAcao(
        label: label,
        icon: icon,
        onTap: onTap,
        destaque: destaque,
      ),
    );
  }
}

class _ItemAcao extends StatelessWidget {
  const _ItemAcao({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destaque = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: 'quick_action_$label',
          backgroundColor: destaque ? AppColors.primary : AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          onPressed: onTap,
          child: Icon(icon, size: 18),
        ),
      ],
    );
  }
}
