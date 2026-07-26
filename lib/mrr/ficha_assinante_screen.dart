import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/lancamentos_bus.dart';
import '../theme.dart';

class FichaAssinanteScreen extends StatefulWidget {
  const FichaAssinanteScreen({super.key, required this.assinatura});

  final Map<String, dynamic> assinatura;

  @override
  State<FichaAssinanteScreen> createState() => _FichaAssinanteScreenState();
}

class _FichaAssinanteScreenState extends State<FichaAssinanteScreen> {
  late Future<_FichaDados> _future;
  bool _baixandoPagamento = false;

  String get _assinaturaId => widget.assinatura['id'] as String;
  String get _clienteNome =>
      widget.assinatura['cliente_nome'] as String? ?? '—';
  double get _valorMensalidade =>
      (widget.assinatura['valor_mensalidade'] as num).toDouble();
  int get _diaVencimento => widget.assinatura['dia_vencimento'] as int;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<_FichaDados> _carregar() async {
    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('assinatura_id', _assinaturaId)
        .order('competencia', ascending: false);

    final criadoEm = DateTime.parse(widget.assinatura['created_at'] as String);
    final agora = DateTime.now();
    final mesesComoAssinante =
        (agora.year - criadoEm.year) * 12 + (agora.month - criadoEm.month) + 1;

    final competenciaAtual = DateTime(agora.year, agora.month);
    final jaPagouMesAtual = transacoes.any((t) {
      final competencia = DateTime.parse(t['competencia'] as String);
      return competencia.year == competenciaAtual.year &&
          competencia.month == competenciaAtual.month;
    });

    return _FichaDados(
      mesesComoAssinante: mesesComoAssinante,
      mensalidadesPagas: transacoes.length,
      pagamentoMesAtualPendente: !jaPagouMesAtual,
      historico: List<Map<String, dynamic>>.from(transacoes),
    );
  }

  Future<void> _baixarPagamento() async {
    final agora = DateTime.now();
    final dataPagamento = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(agora.year - 1),
      lastDate: agora,
      helpText: 'Quando o pagamento foi feito?',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (dataPagamento == null) return;

    setState(() => _baixandoPagamento = true);
    try {
      final dataIso = formatarDataIso(dataPagamento);
      await supabase.rpc(
        'registrar_pagamento_assinatura',
        params: {'p_assinatura_id': _assinaturaId, 'p_data': dataIso},
      );
      notificarLancamentosAtualizados();
      if (mounted) {
        setState(() {
          _future = _carregar();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar pagamento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _baixandoPagamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_clienteNome)),
      body: FutureBuilder<_FichaDados>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final dados = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatarMoeda(_valorMensalidade)}/mês · todo dia $_diaVencimento',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assinante há ${dados.mesesComoAssinante} ${dados.mesesComoAssinante == 1 ? "mês" : "meses"}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MENSALIDADES PAGAS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dados.mensalidadesPagas}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                'MÊS ATUAL',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dados.pagamentoMesAtualPendente
                                    ? 'Pendente'
                                    : 'Pago',
                                style: TextStyle(
                                  color: dados.pagamentoMesAtualPendente
                                      ? AppColors.negative
                                      : AppColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dados.pagamentoMesAtualPendente) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _baixandoPagamento ? null : _baixarPagamento,
                      child: _baixandoPagamento
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Baixar Pagamento'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Histórico de Cobranças',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (dados.historico.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma mensalidade paga ainda',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (final t in dados.historico)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatarCompetencia(
                                  t['competencia'] as String,
                                ),
                              ),
                            ),
                            Text(
                              'Pago em ${_formatarData(t['data_transacao'] as String)}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatarCompetencia(String iso) {
  final d = DateTime.parse(iso);
  const meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${meses[d.month - 1]} de ${d.year}';
}

String _formatarData(String iso) => formatarData(DateTime.parse(iso));

class _FichaDados {
  _FichaDados({
    required this.mesesComoAssinante,
    required this.mensalidadesPagas,
    required this.pagamentoMesAtualPendente,
    required this.historico,
  });

  final int mesesComoAssinante;
  final int mensalidadesPagas;
  final bool pagamentoMesAtualPendente;
  final List<Map<String, dynamic>> historico;
}
