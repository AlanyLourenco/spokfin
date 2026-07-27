import 'package:flutter/material.dart';

import '../lancamentos/anotar_screen.dart';
import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/falar_screen.dart';
import '../lancamentos/ia_service.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../lancamentos/revisar_lancamento_screen.dart';
import '../main.dart';
import '../perfil/perfil_screen.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/lancamentos_bus.dart';
import '../theme.dart';

class _LancamentoResumo {
  _LancamentoResumo({
    required this.id,
    required this.origem,
    required this.data,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.tipo,
    required this.status,
    required this.statusLabel,
    required this.notaFiscalStatus,
    this.clienteId,
    this.clienteNome,
  });

  final String id;
  final String origem;
  final DateTime data;
  final String descricao;
  final String categoria;
  final double valor;
  final String tipo;
  final String status;
  final String statusLabel;
  final String notaFiscalStatus;
  final String? clienteId;
  final String? clienteNome;
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({
    super.key,
    required this.empresaId,
    required this.nomeExibicao,
    this.onVerHistorico,
  });

  final String empresaId;
  final String nomeExibicao;
  final VoidCallback? onVerHistorico;

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _carregar();
    lancamentosAtualizados.addListener(_recarregar);
  }

  @override
  void dispose() {
    lancamentosAtualizados.removeListener(_recarregar);
    super.dispose();
  }

  void _recarregar() {
    setState(() {
      _dataFuture = _carregar();
    });
  }

  static const _diasAlertaVencimento = 3;

  Future<_HomeData> _carregar() async {
    final saldo = await supabase.rpc(
      'calcular_saldo',
      params: {'p_empresa_id': widget.empresaId},
    );

    final pendentes = await supabase
        .from('contas_pagar_receber')
        .select('tipo, valor')
        .eq('empresa_id', widget.empresaId)
        .eq('status', 'pendente');

    double aReceber = 0;
    double aPagar = 0;
    for (final row in pendentes) {
      final valor = (row['valor'] as num).toDouble();
      if (row['tipo'] == 'receber') {
        aReceber += valor;
      } else {
        aPagar += valor;
      }
    }

    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .order('data_transacao', ascending: false)
        .limit(5);

    final contas = await supabase
        .from('contas_pagar_receber_vw')
        .select()
        .eq('empresa_id', widget.empresaId)
        .neq('status_efetivo', 'pago')
        .order('vencimento', ascending: false)
        .limit(5);

    final hoje = DateTime.now();
    final limiteVencimento = hoje.add(
      const Duration(days: _diasAlertaVencimento),
    );
    final vencendoRows = await supabase
        .from('contas_pagar_receber_vw')
        .select()
        .eq('empresa_id', widget.empresaId)
        .eq('status_efetivo', 'pendente')
        .gte('vencimento', hoje.toIso8601String().split('T').first)
        .lte('vencimento', limiteVencimento.toIso8601String().split('T').first)
        .order('vencimento');

    final clienteIds = <String>{
      for (final t in transacoes)
        if (t['cliente_id'] != null) t['cliente_id'] as String,
      for (final c in contas)
        if (c['cliente_id'] != null) c['cliente_id'] as String,
      for (final c in vencendoRows)
        if (c['cliente_id'] != null) c['cliente_id'] as String,
    }.toList();

    final clientes = clienteIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('clientes')
                .select('id, nome')
                .inFilter('id', clienteIds),
          );
    final nomesPorId = {
      for (final c in clientes) c['id'] as String: c['nome'] as String,
    };

    _LancamentoResumo construirResumoConta(Map<String, dynamic> c) {
      return _LancamentoResumo(
        id: c['id'] as String,
        origem: 'conta',
        data: DateTime.parse(c['vencimento'] as String),
        descricao: c['descricao'] as String? ?? '',
        categoria: c['categoria'] as String? ?? '',
        valor: (c['valor'] as num).toDouble(),
        tipo: c['tipo'] == 'receber' ? 'entrada' : 'saida',
        status: c['status_efetivo'] as String,
        statusLabel: c['status_efetivo'] == 'atrasado'
            ? 'Atrasado'
            : 'Pendente',
        notaFiscalStatus: c['nota_fiscal_status'] as String,
        clienteId: c['cliente_id'] as String?,
        clienteNome: c['cliente_id'] == null
            ? null
            : nomesPorId[c['cliente_id']],
      );
    }

    final recentes = <_LancamentoResumo>[
      for (final t in transacoes)
        _LancamentoResumo(
          id: t['id'] as String,
          origem: 'transacao',
          data: DateTime.parse(t['data_transacao'] as String),
          descricao: t['descricao'] as String? ?? '',
          categoria: t['categoria'] as String? ?? '',
          valor: (t['valor'] as num).toDouble(),
          tipo: t['tipo'] as String,
          status: 'pago',
          statusLabel: 'Pago',
          notaFiscalStatus: t['nota_fiscal_status'] as String,
          clienteId: t['cliente_id'] as String?,
          clienteNome: t['cliente_id'] == null
              ? null
              : nomesPorId[t['cliente_id']],
        ),
      for (final c in contas) construirResumoConta(c),
    ]..sort((a, b) => b.data.compareTo(a.data));

    final vencendoEmBreve = [
      for (final c in vencendoRows) construirResumoConta(c),
    ]..sort((a, b) => a.data.compareTo(b.data));

    return _HomeData(
      saldo: (saldo as num).toDouble(),
      aReceber: aReceber,
      aPagar: aPagar,
      recentes: recentes.take(5).toList(),
      vencendoEmBreve: vencendoEmBreve,
    );
  }

  Future<void> _abrirFalar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FalarScreen(empresaId: widget.empresaId),
      ),
    );
    _recarregar();
  }

  Future<void> _abrirAnotar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnotarScreen(empresaId: widget.empresaId),
      ),
    );
    _recarregar();
  }

  Future<void> _abrirManual() async {
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
    _recarregar();
  }

  Future<void> _abrirDetalhes(_LancamentoResumo item) async {
    final alterou = await mostrarDetalhesLancamento(
      context,
      empresaId: widget.empresaId,
      lancamento: LancamentoDetalhado(
        id: item.id,
        origem: item.origem,
        descricao: item.descricao,
        categoria: item.categoria,
        valor: item.valor,
        tipo: item.tipo,
        data: item.data,
        status: item.status,
        clienteId: item.clienteId,
        clienteNome: item.clienteNome,
        notaFiscalStatus: item.notaFiscalStatus,
      ),
    );
    if (alterou == true) _recarregar();
  }

  String get _iniciais => iniciaisDoNome(widget.nomeExibicao);

  void _abrirPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilScreen(empresaId: widget.empresaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final dados = snapshot.data!;
          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'spokfin',
                          style: TextStyle(
                            fontFamily: 'Calistoga',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _abrirPerfil,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceAlt,
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Text(
                              _iniciais,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    AppCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SALDO ATUAL',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatarValorCifrao(dados.saldo),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  label: 'A RECEBER',
                                  valor: dados.aReceber,
                                  cor: AppColors.accent,
                                ),
                              ),
                              Expanded(
                                child: _MiniStat(
                                  label: 'A PAGAR',
                                  valor: dados.aPagar,
                                  cor: AppColors.negative,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (dados.vencendoEmBreve.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.negative,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'VENCENDO EM BREVE',
                                  style: TextStyle(
                                    color: AppColors.negative,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            for (final l in dados.vencendoEmBreve)
                              _LancamentoTile(
                                lancamento: l,
                                onTap: () => _abrirDetalhes(l),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lançamentos Recentes',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.onVerHistorico != null)
                          TextButton(
                            onPressed: widget.onVerHistorico,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ver tudo',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    if (dados.recentes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Nenhum lançamento ainda',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < dados.recentes.length; i++) ...[
                        _LancamentoTile(
                          lancamento: dados.recentes[i],
                          onTap: () => _abrirDetalhes(dados.recentes[i]),
                        ),
                        if (i < dados.recentes.length - 1)
                          const Divider(color: AppColors.hairline, height: 1),
                      ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: InkWell(
                            onTap: _abrirFalar,
                            borderRadius: BorderRadius.circular(22),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Falar',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _abrirAnotar,
                            borderRadius: BorderRadius.circular(22),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Anotar',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _abrirManual,
                            borderRadius: BorderRadius.circular(22),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Manual',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeData {
  _HomeData({
    required this.saldo,
    required this.aReceber,
    required this.aPagar,
    required this.recentes,
    required this.vencendoEmBreve,
  });

  final double saldo;
  final double aReceber;
  final double aPagar;
  final List<_LancamentoResumo> recentes;
  final List<_LancamentoResumo> vencendoEmBreve;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.valor,
    required this.cor,
  });

  final String label;
  final double valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          formatarValorCifrao(valor),
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _LancamentoTile extends StatelessWidget {
  const _LancamentoTile({required this.lancamento, required this.onTap});

  final _LancamentoResumo lancamento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positivo = lancamento.tipo == 'entrada';
    final cor = positivo ? AppColors.accent : AppColors.negative;
    final sinal = positivo ? '+' : '-';
    final subtitulo = [
      if (lancamento.categoria.isNotEmpty) lancamento.categoria,
      lancamento.statusLabel,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lancamento.descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (lancamento.notaFiscalStatus == 'pendente') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 10,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'NFC-e agendada',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sinal ${formatarValorCifrao(lancamento.valor)}',
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
