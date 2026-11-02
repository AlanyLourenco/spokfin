import 'package:flutter/material.dart';

import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../lancamentos/lancamentos_repository.dart';
import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/motion.dart';
import '../theme.dart';
import 'adicionar_encarregado_sheet.dart';
import 'cliente_form_screen.dart';

class FichaClienteScreen extends StatefulWidget {
  const FichaClienteScreen({
    super.key,
    required this.empresaId,
    required this.cliente,
  });

  final String empresaId;
  final Map<String, dynamic> cliente;

  @override
  State<FichaClienteScreen> createState() => _FichaClienteScreenState();
}

class _FichaClienteScreenState extends State<FichaClienteScreen> {
  late Map<String, dynamic> _cliente;
  late Future<_FichaClienteDados> _future;

  String get _clienteId => _cliente['id'] as String;
  String get _nome => _cliente['nome'] as String? ?? '';
  String? get _telefone => _cliente['telefone'] as String?;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _future = _carregar();
  }

  /// Quantos lançamentos do histórico já estão à mostra. A lista renderizava
  /// tudo de uma vez: um cliente antigo com centenas de lançamentos virava uma
  /// rolagem infinita, e todos os widgets eram construídos de saída.
  static const _passoHistorico = 10;
  int _visiveisHistorico = _passoHistorico;

  void _recarregar() {
    _visiveisHistorico = _passoHistorico;
    setState(() {
      _future = _carregar();
    });
  }

  Future<_FichaClienteDados> _carregar() async {
    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('cliente_id', _clienteId)
        .order('data_transacao', ascending: false);

    final contas = await supabase
        .from('contas_pagar_receber')
        .select()
        .eq('cliente_id', _clienteId)
        .order('vencimento', ascending: false);

    final encarregados = await supabase
        .from('encarregados')
        .select()
        .eq('cliente_id', _clienteId)
        .order('created_at');

    double totalPago = 0;
    for (final t in transacoes) {
      if (t['tipo'] == 'entrada') totalPago += (t['valor'] as num).toDouble();
    }

    double debito = 0;
    for (final c in contas) {
      if (c['tipo'] == 'receber' && c['status'] == 'pendente') {
        debito += (c['valor'] as num).toDouble();
      }
    }

    final historico = await buscarLancamentos(
      clienteId: _clienteId,
      incluirContasPagas: true,
    );

    // interações por mês: últimos 6 meses, contando transações + contas
    final agora = DateTime.now();
    final meses = List.generate(
      6,
      (i) => DateTime(agora.year, agora.month - (5 - i)),
    );
    final contagemPorMes = {for (final m in meses) '${m.year}-${m.month}': 0};
    for (final item in historico) {
      final chave = '${item.data.year}-${item.data.month}';
      if (contagemPorMes.containsKey(chave)) {
        contagemPorMes[chave] = contagemPorMes[chave]! + 1;
      }
    }

    return _FichaClienteDados(
      totalPago: totalPago,
      debito: debito,
      servicosPrestados: transacoes.length + contas.length,
      historico: historico,
      encarregados: List<Map<String, dynamic>>.from(encarregados),
      interacoesPorMes: meses
          .map((m) => contagemPorMes['${m.year}-${m.month}']!)
          .toList(),
    );
  }

  Future<void> _editar() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClienteFormScreen(empresaId: widget.empresaId, cliente: _cliente),
      ),
    );
    if (alterou == true) {
      final atualizado = await supabase
          .from('clientes')
          .select()
          .eq('id', _clienteId)
          .single();
      setState(() => _cliente = atualizado);
      _recarregar();
    }
  }

  Future<void> _abrirDetalhes(LancamentoDetalhado item) async {
    final alterou = await mostrarDetalhesLancamento(
      context,
      empresaId: widget.empresaId,
      lancamento: item,
    );
    if (alterou == true) _recarregar();
  }

  Future<void> _adicionarEncarregado() async {
    final salvou = await mostrarFormularioEncarregado(
      context,
      empresaId: widget.empresaId,
      clienteId: _clienteId,
    );
    if (salvou == true) _recarregar();
  }

  Future<void> _excluirOuArquivar() async {
    final temTransacao = await supabase
        .from('transacoes')
        .select('id')
        .eq('cliente_id', _clienteId)
        .limit(1);
    final temConta = await supabase
        .from('contas_pagar_receber')
        .select('id')
        .eq('cliente_id', _clienteId)
        .limit(1);
    final temLancamentos = temTransacao.isNotEmpty || temConta.isNotEmpty;

    if (!mounted) return;
    if (temLancamentos) {
      final arquivar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cliente com lançamentos'),
          content: Text(
            '"$_nome" tem lançamentos vinculados, então não pode ser excluído — isso apagaria o histórico. Você pode arquivá-lo: ele some da lista de clientes, mas o histórico continua intacto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar cliente'),
            ),
          ],
        ),
      );
      if (arquivar != true) return;
      await supabase
          .from('clientes')
          .update({'ativo': false})
          .eq('id', _clienteId);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final excluir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text(
          '"$_nome" não tem nenhum lançamento vinculado. Isso vai excluí-lo permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (excluir != true) return;
    await supabase.from('clientes').delete().eq('id', _clienteId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha do Cliente'),
        actions: [
          IconButton(
            onPressed: _excluirOuArquivar,
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Excluir cliente',
          ),
          TextButton.icon(
            onPressed: _editar,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: FutureBuilder<_FichaClienteDados>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.entrada,
              switchOutCurve: AppMotion.saida,
              child: const KeyedSubtree(
                key: ValueKey('carregando'),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.entrada,
              switchOutCurve: AppMotion.saida,
              child: KeyedSubtree(
                key: const ValueKey('erro'),
                child: Center(child: Text('Erro: ${snapshot.error}')),
              ),
            );
          }
          final dados = snapshot.data!;
          final emDebito = dados.debito > 0;
          final iniciais = iniciaisDoNome(_nome);

          return AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.entrada,
            switchOutCurve: AppMotion.saida,
            child: KeyedSubtree(
              key: const ValueKey('conteudo'),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: Text(
                          iniciais,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_telefone != null && _telefone!.isNotEmpty)
                              Text(
                                _telefone!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const RotuloCard('STATUS'),
                        Text(
                          emDebito
                              ? 'Em Débito: ${formatarMoeda(dados.debito)}'
                              : 'Sem Pendências',
                          style: TextStyle(
                            color: emDebito
                                ? AppColors.negative
                                : AppColors.accent,
                            fontWeight: FontWeight.bold,
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
                                'TOTAL PAGO',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatarMoeda(dados.totalPago),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 18,
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
                                'SERVIÇOS PRESTADOS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dados.servicosPrestados}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INTERAÇÕES POR MÊS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MiniBarChart(valores: dados.interacoesPorMes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Encarregados',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _adicionarEncarregado,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('+ Adicionar Encarregado'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dados.encarregados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum encarregado.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (final e in dados.encarregados)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      [
                                        e['nome'] as String,
                                        if ((e['cargo'] as String?)
                                                ?.isNotEmpty ==
                                            true)
                                          e['cargo'] as String,
                                      ].join(' · '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((e['telefone'] as String?)?.isNotEmpty ==
                                  true)
                                Text(
                                  e['telefone'] as String,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  const Text(
                    'Histórico',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (dados.historico.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum lançamento ainda.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (final h
                        in dados.historico.take(_visiveisHistorico))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _abrirDetalhes(h),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: h.pago
                                      ? AppColors.accent
                                      : AppColors.negative,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.descricao.isEmpty
                                          ? 'Sem descrição'
                                          : h.descricao,
                                      style: TextStyle(
                                        color: h.descricao.isEmpty
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                        fontStyle: h.descricao.isEmpty
                                            ? FontStyle.italic
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      '${formatarData(h.data)} · ${h.pago ? 'Pago' : 'Pendente'}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${h.tipo == 'entrada' ? '+' : '-'} ${formatarMoeda(h.valor)}',
                                style: TextStyle(
                                  color: h.tipo == 'entrada'
                                      ? AppColors.accent
                                      : AppColors.negative,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (dados.historico.length > _visiveisHistorico)
                    Center(
                      child: TextButton(
                        onPressed: () => setState(
                          () => _visiveisHistorico += _passoHistorico,
                        ),
                        child: Text(
                          'Ver mais (${dados.historico.length - _visiveisHistorico} restantes)',
                        ),
                      ),
                    ),
                ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.valores});

  final List<int> valores;

  @override
  Widget build(BuildContext context) {
    final maximo = valores.isEmpty
        ? 1
        : valores.reduce((a, b) => a > b ? a : b).clamp(1, 999);
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in valores)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: 6 + (v / maximo) * 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FichaClienteDados {
  _FichaClienteDados({
    required this.totalPago,
    required this.debito,
    required this.servicosPrestados,
    required this.historico,
    required this.encarregados,
    required this.interacoesPorMes,
  });

  final double totalPago;
  final double debito;
  final int servicosPrestados;
  final List<LancamentoDetalhado> historico;
  final List<Map<String, dynamic>> encarregados;
  final List<int> interacoesPorMes;
}
