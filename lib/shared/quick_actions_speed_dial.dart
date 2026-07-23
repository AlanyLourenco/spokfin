import 'package:flutter/material.dart';

import '../lancamentos/anotar_screen.dart';
import '../lancamentos/falar_screen.dart';
import '../lancamentos/ia_service.dart';
import '../lancamentos/revisar_lancamento_screen.dart';
import '../theme.dart';

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

class _QuickActionsSpeedDialState extends State<QuickActionsSpeedDial> {
  bool _aberto = false;

  Future<void> _abrirFalar() async {
    setState(() => _aberto = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FalarScreen(empresaId: widget.empresaId),
      ),
    );
    widget.onConcluido?.call();
  }

  Future<void> _abrirAnotar() async {
    setState(() => _aberto = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnotarScreen(empresaId: widget.empresaId),
      ),
    );
    widget.onConcluido?.call();
  }

  Future<void> _abrirManual() async {
    setState(() => _aberto = false);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_aberto) ...[
          _ItemAcao(label: 'Manual', icon: Icons.add, onTap: _abrirManual),
          const SizedBox(height: 10),
          _ItemAcao(
            label: 'Anotar',
            icon: Icons.edit_note,
            onTap: _abrirAnotar,
          ),
          const SizedBox(height: 10),
          _ItemAcao(
            label: 'Falar',
            icon: Icons.mic,
            onTap: _abrirFalar,
            destaque: true,
          ),
          const SizedBox(height: 14),
        ],
        FloatingActionButton(
          heroTag: 'quick_actions_toggle',
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          onPressed: () => setState(() => _aberto = !_aberto),
          child: Icon(_aberto ? Icons.close : Icons.add),
        ),
      ],
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
            color: AppColors.surfaceAlt,
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
          backgroundColor: destaque ? AppColors.accent : AppColors.surfaceAlt,
          foregroundColor: destaque ? Colors.black : AppColors.textPrimary,
          onPressed: onTap,
          child: Icon(icon, size: 18),
        ),
      ],
    );
  }
}
