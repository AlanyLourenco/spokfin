import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'editar_lancamento_screen.dart';
import 'lancamento_detalhado.dart';
import 'recibo_dialog.dart';

class DetalhesLancamentoScreen extends StatefulWidget {
  const DetalhesLancamentoScreen({
    super.key,
    required this.empresaId,
    required this.lancamento,
  });

  final String empresaId;
  final LancamentoDetalhado lancamento;

  @override
  State<DetalhesLancamentoScreen> createState() =>
      _DetalhesLancamentoScreenState();
}

class _DetalhesLancamentoScreenState extends State<DetalhesLancamentoScreen> {
  late LancamentoDetalhado _lancamento;
  bool _loading = false;

  bool get _pago => _lancamento.status == 'pago';
  bool get _entrada => _lancamento.tipo == 'entrada';
  bool get _notaFiscalPendente => _lancamento.notaFiscalStatus == 'pendente';

  @override
  void initState() {
    super.initState();
    _lancamento = widget.lancamento;
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Erro: $e')));
  }

  Future<void> _marcarPago() async {
    setState(() => _loading = true);
    try {
      await supabase.rpc(
        'registrar_pagamento',
        params: {'p_conta_id': _lancamento.id},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marcarPendente() async {
    setState(() => _loading = true);
    try {
      await supabase.rpc(
        'marcar_lancamento_pendente',
        params: {'p_transacao_id': _lancamento.id},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editar() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditarLancamentoScreen(
          empresaId: widget.empresaId,
          lancamento: _lancamento,
        ),
      ),
    );
    // O id/origem podem mudar (ex: status pago -> pendente move a linha de
    // tabela), então em vez de tentar atualizar o estado local, fecha esta
    // tela e deixa quem chamou recarregar a lista.
    if (alterou == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _marcarNotaFiscalEmitida() async {
    setState(() => _loading = true);
    try {
      final tabela = _lancamento.origem == 'transacao'
          ? 'transacoes'
          : 'contas_pagar_receber';
      await supabase
          .from(tabela)
          .update({'nota_fiscal_status': 'emitida'})
          .eq('id', _lancamento.id);
      setState(
        () => _lancamento = _lancamento.copiarCom(
          notaFiscalStatus: 'emitida',
        ),
      );
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text(
          'Isso vai apagar "${_lancamento.descricao}" (${formatarMoeda(_lancamento.valor)}) permanentemente. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() => _loading = true);
    try {
      final tabela = _lancamento.origem == 'transacao'
          ? 'transacoes'
          : 'contas_pagar_receber';
      await supabase.from(tabela).delete().eq('id', _lancamento.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarRecibo() async {
    var numero = 1;
    if (_lancamento.clienteId != null) {
      final anteriores = await supabase
          .from('transacoes')
          .select('id')
          .eq('cliente_id', _lancamento.clienteId!)
          .eq('tipo', 'entrada')
          .lte(
            'data_transacao',
            _lancamento.data.toIso8601String().split('T').first,
          )
          .order('data_transacao');
      numero = anteriores.length.clamp(1, 999999);
    }
    if (!mounted) return;
    await mostrarRecibo(context, lancamento: _lancamento, numero: numero);
  }

  @override
  Widget build(BuildContext context) {
    final positivo = _lancamento.tipo == 'entrada';
    final cor = positivo ? AppColors.accent : AppColors.negative;
    final sinal = positivo ? '+' : '-';
    final statusLabel = _pago
        ? 'Pago'
        : (_lancamento.status == 'atrasado' ? 'Atrasado' : 'Pendente');
    final statusCor = _pago ? AppColors.accent : AppColors.negative;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Lançamento'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _editar,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _lancamento.categoria.isEmpty ? '—' : _lancamento.categoria,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _lancamento.descricao,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$sinal ${formatarMoeda(_lancamento.valor)}',
                style: TextStyle(
                  color: cor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATA',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatarData(_lancamento.data)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusCor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_lancamento.clienteNome != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIENTE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_lancamento.clienteNome!),
                    ],
                  ),
                ),
              ],
              if (_lancamento.notaFiscalStatus != 'nao_aplicavel') ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: _notaFiscalPendente
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _notaFiscalPendente
                              ? 'NFC-e agendada'
                              : 'NFC-e emitida',
                        ),
                      ),
                      if (_notaFiscalPendente)
                        TextButton(
                          onPressed: _loading
                              ? null
                              : _marcarNotaFiscalEmitida,
                          child: const Text('Marcar como emitida'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_pago)
                OutlinedButton(
                  onPressed: _loading ? null : _marcarPendente,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Marcar Pendente'),
                )
              else
                FilledButton(
                  onPressed: _loading ? null : _marcarPago,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Marcar Pago'),
                ),
              if (_pago && _entrada) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _gerarRecibo,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Gerar Recibo'),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _confirmarExclusao,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.negative,
                  side: const BorderSide(color: AppColors.negative),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Excluir Lançamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatarData(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
