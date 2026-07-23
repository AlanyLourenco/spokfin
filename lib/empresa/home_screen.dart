import 'package:flutter/material.dart';

import '../lancamentos/anotar_screen.dart';
import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/falar_screen.dart';
import '../lancamentos/ia_service.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../lancamentos/revisar_lancamento_screen.dart';
import '../main.dart';
import '../mrr/ficha_assinante_screen.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
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

    final assinaturasAtrasadasRows = await supabase
        .from('assinaturas_com_status')
        .select()
        .eq('empresa_id', widget.empresaId)
        .eq('status_mes_atual', 'atrasado');

    final clienteIds = <String>{
      for (final t in transacoes)
        if (t['cliente_id'] != null) t['cliente_id'] as String,
      for (final c in contas)
        if (c['cliente_id'] != null) c['cliente_id'] as String,
      for (final c in vencendoRows)
        if (c['cliente_id'] != null) c['cliente_id'] as String,
      for (final a in assinaturasAtrasadasRows) a['cliente_id'] as String,
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

    final inicioJanela = DateTime(hoje.year, hoje.month - 5, 1);
    final transacoesJanela = await supabase
        .from('transacoes')
        .select('tipo, valor, data_transacao')
        .eq('empresa_id', widget.empresaId)
        .gte(
          'data_transacao',
          inicioJanela.toIso8601String().split('T').first,
        );

    final mesesJanela = List.generate(
      6,
      (i) => DateTime(hoje.year, hoje.month - (5 - i)),
    );
    final netPorMes = {
      for (final m in mesesJanela) '${m.year}-${m.month}': 0.0,
    };
    for (final t in transacoesJanela) {
      final data = DateTime.parse(t['data_transacao'] as String);
      final chave = '${data.year}-${data.month}';
      if (netPorMes.containsKey(chave)) {
        final valor = (t['valor'] as num).toDouble();
        netPorMes[chave] =
            netPorMes[chave]! + (t['tipo'] == 'entrada' ? valor : -valor);
      }
    }

    final assinaturasAtrasadas = [
      for (final a in assinaturasAtrasadasRows)
        {...a, 'cliente_nome': nomesPorId[a['cliente_id']] ?? '—'},
    ];

    return _HomeData(
      saldo: (saldo as num).toDouble(),
      aReceber: aReceber,
      aPagar: aPagar,
      recentes: recentes.take(5).toList(),
      vencendoEmBreve: vencendoEmBreve,
      assinaturasAtrasadas: assinaturasAtrasadas,
      evolucaoSaldo: mesesJanela.map((m) => netPorMes['${m.year}-${m.month}']!).toList(),
      rotulosMeses: mesesJanela.map((m) => _nomesMeses[m.month - 1]).toList(),
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
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetalhesLancamentoScreen(
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
        ),
      ),
    );
    if (alterou == true) _recarregar();
  }

  Future<void> _abrirFichaAssinante(Map<String, dynamic> assinatura) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FichaAssinanteScreen(assinatura: assinatura),
      ),
    );
    _recarregar();
  }

  String get _iniciais {
    final nome = widget.nomeExibicao.trim();
    if (nome.isEmpty) return '?';
    return nome
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
  }

  Future<void> _abrirMenuPerfil() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceAlt,
                child: Text(
                  _iniciais,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                widget.nomeExibicao,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.negative),
              title: const Text(
                'Sair',
                style: TextStyle(color: AppColors.negative),
              ),
              onTap: () {
                Navigator.of(context).pop();
                supabase.auth.signOut();
              },
            ),
          ],
        ),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'spokfin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _abrirMenuPerfil,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceAlt,
                          child: Text(
                            _iniciais,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SALDO ATUAL',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatarMoeda(dados.saldo),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.negative,
                                  size: 18,
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
                            const SizedBox(height: 8),
                            for (final l in dados.vencendoEmBreve)
                              _LancamentoTile(
                                lancamento: l,
                                onTap: () => _abrirDetalhes(l),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (dados.assinaturasAtrasadas.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.negative,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ASSINATURAS ATRASADAS',
                                  style: TextStyle(
                                    color: AppColors.negative,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final a in dados.assinaturasAtrasadas)
                              InkWell(
                                onTap: () => _abrirFichaAssinante(a),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a['cliente_nome'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${formatarMoeda(a['valor_mensalidade'] as num)}/mês',
                                        style: const TextStyle(
                                          color: AppColors.negative,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EVOLUÇÃO DO SALDO',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SaldoMesChart(
                            valores: dados.evolucaoSaldo,
                            rotulos: dados.rotulosMeses,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lançamentos Recentes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (widget.onVerHistorico != null)
                          TextButton(
                            onPressed: widget.onVerHistorico,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                            ),
                            child: const Text('Ver tudo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                          const Divider(color: AppColors.border, height: 1),
                      ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: InkWell(
                            onTap: _abrirFalar,
                            borderRadius: BorderRadius.circular(22),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic, size: 18, color: Colors.black),
                                SizedBox(width: 6),
                                Text(
                                  'Falar',
                                  style: TextStyle(
                                    color: Colors.black,
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
                                  SizedBox(width: 6),
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
                                  SizedBox(width: 6),
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

const _nomesMeses = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

class _HomeData {
  _HomeData({
    required this.saldo,
    required this.aReceber,
    required this.aPagar,
    required this.recentes,
    required this.vencendoEmBreve,
    required this.assinaturasAtrasadas,
    required this.evolucaoSaldo,
    required this.rotulosMeses,
  });

  final double saldo;
  final double aReceber;
  final double aPagar;
  final List<_LancamentoResumo> recentes;
  final List<_LancamentoResumo> vencendoEmBreve;
  final List<Map<String, dynamic>> assinaturasAtrasadas;
  final List<double> evolucaoSaldo;
  final List<String> rotulosMeses;
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
          formatarMoeda(valor),
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SaldoMesChart extends StatelessWidget {
  const _SaldoMesChart({required this.valores, required this.rotulos});

  final List<double> valores;
  final List<String> rotulos;

  @override
  Widget build(BuildContext context) {
    final maximo = valores.isEmpty
        ? 1.0
        : valores
              .map((v) => v.abs())
              .reduce((a, b) => a > b ? a : b)
              .clamp(1.0, double.infinity);
    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < valores.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 6 + (valores[i].abs() / maximo) * 34,
                      decoration: BoxDecoration(
                        color: valores[i] >= 0
                            ? AppColors.accent
                            : AppColors.negative,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rotulos[i],
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lancamento.descricao,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 10,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'NFC-e agendada',
                                style: TextStyle(
                                  color: AppColors.accent,
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
              '$sinal ${formatarMoeda(lancamento.valor)}',
              style: TextStyle(color: cor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
