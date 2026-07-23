import 'dart:math';

import 'package:flutter/material.dart';

import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/lancamentos_bus.dart';
import '../theme.dart';

const _nomesMesesCompletos = [
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

const _paletaCategoria = [
  AppColors.accent,
  AppColors.negative,
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFFA78BFA),
  Color(0xFF5EEAD4),
];

class BalancoScreen extends StatefulWidget {
  const BalancoScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<BalancoScreen> createState() => _BalancoScreenState();
}

class _BalancoScreenState extends State<BalancoScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? _periodoPersonalizado;
  late Future<_BalancoDados> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
    lancamentosAtualizados.addListener(_recarregar);
  }

  @override
  void dispose() {
    lancamentosAtualizados.removeListener(_recarregar);
    super.dispose();
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  Future<void> _abrirSeletorMes() async {
    final agora = DateTime.now();
    final opcoes = List.generate(12, (i) => DateTime(agora.year, agora.month - i));
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 400,
          child: ListView(
            children: [
              for (final m in opcoes)
                ListTile(
                  title: Text('${_nomesMesesCompletos[m.month - 1]} de ${m.year}'),
                  trailing:
                      _periodoPersonalizado == null &&
                          m.year == _mes.year &&
                          m.month == _mes.month
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () {
                    setState(() {
                      _mes = DateTime(m.year, m.month);
                      _periodoPersonalizado = null;
                      _future = _carregar();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              const Divider(color: AppColors.hairline, height: 1),
              ListTile(
                title: const Text('Período personalizado...'),
                trailing: _periodoPersonalizado != null
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _escolherPeriodoPersonalizado();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _escolherPeriodoPersonalizado() async {
    final agora = DateTime.now();
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(agora.year - 5),
      lastDate: DateTime(agora.year + 1),
      initialDateRange: _periodoPersonalizado,
      cancelText: 'Cancelar',
      confirmText: 'Usar',
    );
    if (intervalo != null) {
      setState(() {
        _periodoPersonalizado = intervalo;
        _future = _carregar();
      });
    }
  }

  String _rotuloPeriodo() {
    final periodo = _periodoPersonalizado;
    if (periodo != null) {
      return '${_formatarDataCurta(periodo.start)} - ${_formatarDataCurta(periodo.end)}';
    }
    return '${_nomesMesesCompletos[_mes.month - 1]} de ${_mes.year}';
  }

  String _formatarDataCurta(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _abrirDetalhes(_LancamentoMes item) async {
    final alterou = await mostrarDetalhesLancamento(
      context,
      empresaId: widget.empresaId,
      lancamento: LancamentoDetalhado(
        id: item.id,
        origem: 'transacao',
        descricao: item.descricao,
        categoria: item.categoria,
        valor: item.valor,
        tipo: item.tipo,
        data: item.data,
        status: 'pago',
        clienteId: item.clienteId,
        clienteNome: item.clienteNome,
        notaFiscalStatus: item.notaFiscalStatus,
      ),
    );
    if (alterou == true) _recarregar();
  }

  Future<_BalancoDados> _carregar() async {
    final DateTime inicio;
    final DateTime fim;
    final periodo = _periodoPersonalizado;
    if (periodo != null) {
      inicio = DateTime(periodo.start.year, periodo.start.month, periodo.start.day);
      fim = DateTime(periodo.end.year, periodo.end.month, periodo.end.day + 1);
    } else {
      inicio = DateTime(_mes.year, _mes.month, 1);
      fim = DateTime(_mes.year, _mes.month + 1, 1);
    }
    final agruparPorMes = fim.difference(inicio).inDays > 31;

    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .gte('data_transacao', inicio.toIso8601String().split('T').first)
        .lt('data_transacao', fim.toIso8601String().split('T').first)
        .order('data_transacao', ascending: false);

    final clienteIds = <String>{
      for (final t in transacoes)
        if (t['cliente_id'] != null) t['cliente_id'] as String,
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

    double receitas = 0;
    double despesas = 0;
    final entradaPorDia = <DateTime, double>{};
    final saidaPorDia = <DateTime, double>{};
    final categoriaTotais = <String, double>{};
    final lancamentos = <_LancamentoMes>[];

    for (final t in transacoes) {
      final valor = (t['valor'] as num).toDouble();
      final data = DateTime.parse(t['data_transacao'] as String);
      final diaChave = DateTime(data.year, data.month, data.day);
      final tipo = t['tipo'] as String;
      final categoriaBruta = (t['categoria'] as String?)?.trim();
      final categoria = (categoriaBruta == null || categoriaBruta.isEmpty)
          ? 'Outros'
          : categoriaBruta;

      if (tipo == 'entrada') {
        receitas += valor;
        entradaPorDia[diaChave] = (entradaPorDia[diaChave] ?? 0) + valor;
      } else {
        despesas += valor;
        saidaPorDia[diaChave] = (saidaPorDia[diaChave] ?? 0) + valor;
        categoriaTotais[categoria] = (categoriaTotais[categoria] ?? 0) + valor;
      }

      final clienteId = t['cliente_id'] as String?;
      lancamentos.add(
        _LancamentoMes(
          id: t['id'] as String,
          descricao: t['descricao'] as String? ?? '',
          categoria: categoria,
          valor: valor,
          tipo: tipo,
          data: data,
          clienteId: clienteId,
          clienteNome: clienteId == null ? null : nomesPorId[clienteId],
          notaFiscalStatus: t['nota_fiscal_status'] as String,
        ),
      );
    }

    final categoriasDespesa =
        categoriaTotais.entries
            .map((e) => _CategoriaValor(categoria: e.key, valor: e.value))
            .toList()
          ..sort((a, b) => b.valor.compareTo(a.valor));

    final List<_BarraValor> barras;
    if (!agruparPorMes) {
      barras = [
        for (var d = inicio; d.isBefore(fim); d = d.add(const Duration(days: 1)))
          _BarraValor(
            rotulo:
                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
            entrada: entradaPorDia[d] ?? 0,
            saida: saidaPorDia[d] ?? 0,
          ),
      ];
    } else {
      final entradaPorMes = <DateTime, double>{};
      final saidaPorMes = <DateTime, double>{};
      entradaPorDia.forEach((d, v) {
        final chave = DateTime(d.year, d.month);
        entradaPorMes[chave] = (entradaPorMes[chave] ?? 0) + v;
      });
      saidaPorDia.forEach((d, v) {
        final chave = DateTime(d.year, d.month);
        saidaPorMes[chave] = (saidaPorMes[chave] ?? 0) + v;
      });
      final ultimoDiaIncluso = fim.subtract(const Duration(days: 1));
      final ultimoMes = DateTime(ultimoDiaIncluso.year, ultimoDiaIncluso.month);
      final cruzaAno = inicio.year != ultimoMes.year;
      barras = [
        for (
          var m = DateTime(inicio.year, inicio.month);
          !m.isAfter(ultimoMes);
          m = DateTime(m.year, m.month + 1)
        )
          _BarraValor(
            rotulo: cruzaAno
                ? '${_nomesMesesCompletos[m.month - 1].substring(0, 3)}/${m.year.toString().substring(2)}'
                : _nomesMesesCompletos[m.month - 1].substring(0, 3),
            entrada: entradaPorMes[m] ?? 0,
            saida: saidaPorMes[m] ?? 0,
          ),
      ];
    }

    return _BalancoDados(
      receitas: receitas,
      despesas: despesas,
      barras: barras,
      categoriasDespesa: categoriasDespesa,
      lancamentos: lancamentos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balancete Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: supabase.auth.signOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FutureBuilder<_BalancoDados>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              final dados = snapshot.data!;
              final liquido = dados.receitas - dados.despesas;
              final totalDespesas = dados.categoriasDespesa.fold<double>(
                0,
                (s, c) => s + c.valor,
              );
              final maiorCategoria = dados.categoriasDespesa.isEmpty
                  ? 1.0
                  : dados.categoriasDespesa.first.valor;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InkWell(
                        onTap: _abrirSeletorMes,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _rotuloPeriodo(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LUCRO LÍQUIDO',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatarValorCifrao(liquido),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: liquido >= 0
                                  ? AppColors.accent
                                  : AppColors.negative,
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
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FATURAMENTO',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatarValorCifrao(dados.receitas),
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CUSTOS',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatarValorCifrao(dados.despesas),
                                  style: const TextStyle(
                                    color: AppColors.negative,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ENTRADAS VS SAÍDAS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _legendaPonto(AppColors.accent, 'in'),
                                  const SizedBox(width: 10),
                                  _legendaPonto(AppColors.negative, 'out'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _EntradasSaidasChart(barras: dados.barras),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GASTOS POR CATEGORIA',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (dados.categoriasDespesa.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  _periodoPersonalizado != null
                                      ? 'Nenhum gasto registrado neste período'
                                      : 'Nenhum gasto registrado neste mês',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _DonutChart(
                                  tamanho: 96,
                                  fatias: [
                                    for (
                                      var i = 0;
                                      i < dados.categoriasDespesa.length;
                                      i++
                                    )
                                      _FatiaCategoria(
                                        valor: dados.categoriasDespesa[i].valor,
                                        cor:
                                            _paletaCategoria[i %
                                                _paletaCategoria.length],
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < dados.categoriasDespesa.length;
                                        i++
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      _paletaCategoria[i %
                                                          _paletaCategoria
                                                              .length],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  dados
                                                      .categoriasDespesa[i]
                                                      .categoria,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${(dados.categoriasDespesa[i].valor / totalDespesas * 100).round()}%',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.hairline, height: 1),
                            const SizedBox(height: 12),
                            for (
                              var i = 0;
                              i < dados.categoriasDespesa.length;
                              i++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dados.categoriasDespesa[i].categoria,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          formatarValorCifrao(
                                            dados.categoriasDespesa[i].valor,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value:
                                            dados.categoriasDespesa[i].valor /
                                            maiorCategoria,
                                        minHeight: 6,
                                        backgroundColor: AppColors.surfaceAlt,
                                        color:
                                            _paletaCategoria[i %
                                                _paletaCategoria.length],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (_periodoPersonalizado != null
                              ? 'LANÇAMENTOS DO PERÍODO'
                              : 'LANÇAMENTOS DE ${_nomesMesesCompletos[_mes.month - 1]} DE ${_mes.year}')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (dados.lancamentos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            _periodoPersonalizado != null
                                ? 'Nenhum lançamento neste período'
                                : 'Nenhum lançamento neste mês',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      for (final item in dados.lancamentos)
                        _LancamentoMesTile(
                          item: item,
                          onTap: () => _abrirDetalhes(item),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _legendaPonto(Color cor, String rotulo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
        ),
        const SizedBox(width: 4),
        Text(
          rotulo,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _BalancoDados {
  _BalancoDados({
    required this.receitas,
    required this.despesas,
    required this.barras,
    required this.categoriasDespesa,
    required this.lancamentos,
  });

  final double receitas;
  final double despesas;
  final List<_BarraValor> barras;
  final List<_CategoriaValor> categoriasDespesa;
  final List<_LancamentoMes> lancamentos;
}

class _BarraValor {
  _BarraValor({required this.rotulo, required this.entrada, required this.saida});

  final String rotulo;
  final double entrada;
  final double saida;
}

class _CategoriaValor {
  _CategoriaValor({required this.categoria, required this.valor});

  final String categoria;
  final double valor;
}

class _LancamentoMes {
  _LancamentoMes({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.notaFiscalStatus,
    this.clienteId,
    this.clienteNome,
  });

  final String id;
  final String descricao;
  final String categoria;
  final double valor;
  final String tipo;
  final DateTime data;
  final String notaFiscalStatus;
  final String? clienteId;
  final String? clienteNome;
}

class _EntradasSaidasChart extends StatelessWidget {
  const _EntradasSaidasChart({required this.barras});

  final List<_BarraValor> barras;

  @override
  Widget build(BuildContext context) {
    final maximo = [
      for (final b in barras) ...[b.entrada, b.saida],
    ].fold<double>(1, (m, v) => v > m ? v : m);

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final b in barras)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            height: 3 + (b.entrada / maximo) * 60,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Container(
                            height: 3 + (b.saida / maximo) * 60,
                            decoration: BoxDecoration(
                              color: AppColors.negative,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (barras.isNotEmpty)
          Row(
            children: [
              Text(
                barras.first.rotulo,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
              const Spacer(),
              if (barras.length > 2)
                Text(
                  barras[barras.length ~/ 2].rotulo,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              const Spacer(),
              Text(
                barras.last.rotulo,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
      ],
    );
  }
}

class _FatiaCategoria {
  _FatiaCategoria({required this.valor, required this.cor});

  final double valor;
  final Color cor;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.fatias, required this.tamanho});

  final List<_FatiaCategoria> fatias;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(painter: _DonutPainter(fatias)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.fatias);

  final List<_FatiaCategoria> fatias;

  @override
  void paint(Canvas canvas, Size size) {
    final total = fatias.fold<double>(0, (s, f) => s + f.valor);
    if (total <= 0) return;

    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    var anguloInicial = -pi / 2;
    const gap = 0.03;
    for (final fatia in fatias) {
      final varredura = (fatia.valor / total) * 2 * pi;
      final paint = Paint()
        ..color = fatia.cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        anguloInicial + gap / 2,
        (varredura - gap).clamp(0, varredura),
        false,
        paint,
      );
      anguloInicial += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.fatias != fatias;
}

class _LancamentoMesTile extends StatelessWidget {
  const _LancamentoMesTile({required this.item, required this.onTap});

  final _LancamentoMes item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positivo = item.tipo == 'entrada';
    final cor = positivo ? AppColors.accent : AppColors.negative;
    final sinal = positivo ? '+' : '-';
    final subtitulo =
        '${item.data.day.toString().padLeft(2, '0')}/${item.data.month.toString().padLeft(2, '0')}/${item.data.year} · Pago · ${item.categoria}';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.descricao,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sinal ${formatarValorCifrao(item.valor)}',
              style: TextStyle(color: cor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
