import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/lancamentos_bus.dart';
import '../theme.dart';

const _tamanhoPagina = 30;

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

class _Item {
  _Item({
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

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<_Item>? _itens;
  bool _temMais = false;
  bool _carregandoMais = false;
  String? _erro;
  int _limite = _tamanhoPagina;

  String _filtro = 'tudo';
  String _periodo = 'todos';
  DateTimeRange? _intervaloPersonalizado;
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
    lancamentosAtualizados.addListener(_recarregar);
  }

  @override
  void dispose() {
    lancamentosAtualizados.removeListener(_recarregar);
    _buscaController.dispose();
    super.dispose();
  }

  void _recarregar() {
    _limite = _tamanhoPagina;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _itens = null;
      _erro = null;
    });
    try {
      final resultado = await _buscarPagina(_limite);
      if (!mounted) return;
      setState(() {
        _itens = resultado.itens;
        _temMais = resultado.temMais;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    }
  }

  Future<void> _carregarMais() async {
    setState(() => _carregandoMais = true);
    _limite += _tamanhoPagina;
    try {
      final resultado = await _buscarPagina(_limite);
      if (!mounted) return;
      setState(() {
        _itens = resultado.itens;
        _temMais = resultado.temMais;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar mais: $e')));
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  /// Busca até `limite` transações e `limite` contas (cada fonte com seu
  /// próprio limite), mescla e ordena por data. Como cada fonte já traz suas
  /// `limite` linhas mais recentes, o topo-`limite` combinado nunca perde um
  /// item que deveria aparecer — só pode trazer itens repetidos de sobra, que
  /// são cortados no final.
  Future<_PaginaHistorico> _buscarPagina(int limite) async {
    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .order('data_transacao', ascending: false)
        .limit(limite);

    final contas = await supabase
        .from('contas_pagar_receber_vw')
        .select()
        .eq('empresa_id', widget.empresaId)
        .neq('status_efetivo', 'pago')
        .order('vencimento', ascending: false)
        .limit(limite);

    final clienteIds = <String>{
      for (final t in transacoes)
        if (t['cliente_id'] != null) t['cliente_id'] as String,
      for (final c in contas)
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

    final itens = <_Item>[
      for (final t in transacoes)
        _Item(
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
      for (final c in contas)
        if (c['status_efetivo'] != 'cancelado')
          _Item(
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
          ),
    ]..sort((a, b) => b.data.compareTo(a.data));

    return _PaginaHistorico(
      itens: itens.take(limite).toList(),
      temMais: transacoes.length >= limite || contas.length >= limite,
    );
  }

  Future<void> _escolherPeriodoPersonalizado() async {
    final agora = DateTime.now();
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(agora.year - 5),
      lastDate: DateTime(agora.year + 1),
      initialDateRange: _intervaloPersonalizado,
      cancelText: 'Cancelar',
      confirmText: 'Usar',
    );
    if (intervalo != null) {
      setState(() {
        _intervaloPersonalizado = intervalo;
        _periodo = 'personalizado';
      });
    }
  }

  Future<void> _abrirSeletorPeriodo() async {
    final agora = DateTime.now();
    final mesPassado = DateTime(agora.year, agora.month - 1);

    void selecionar(String periodo) {
      setState(() => _periodo = periodo);
      Navigator.of(context).pop();
    }

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
              title: const Text('Todos os meses'),
              trailing: _periodo == 'todos'
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => selecionar('todos'),
            ),
            ListTile(
              title: Text(
                'Este Mês (${_nomesMesesCompletos[agora.month - 1]} ${agora.year})',
              ),
              trailing: _periodo == 'este_mes'
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => selecionar('este_mes'),
            ),
            ListTile(
              title: Text(
                'Mês Passado (${_nomesMesesCompletos[mesPassado.month - 1]} ${mesPassado.year})',
              ),
              trailing: _periodo == 'mes_passado'
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => selecionar('mes_passado'),
            ),
            ListTile(
              title: const Text('Período personalizado...'),
              trailing: _periodo == 'personalizado'
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
    );
  }

  String _rotuloPeriodo() {
    final agora = DateTime.now();
    switch (_periodo) {
      case 'este_mes':
        return '${_nomesMesesCompletos[agora.month - 1]} ${agora.year}';
      case 'mes_passado':
        final mesPassado = DateTime(agora.year, agora.month - 1);
        return '${_nomesMesesCompletos[mesPassado.month - 1]} ${mesPassado.year}';
      case 'personalizado':
        if (_intervaloPersonalizado == null) return 'Personalizado';
        return '${formatarDataCurta(_intervaloPersonalizado!.start)} - ${formatarDataCurta(_intervaloPersonalizado!.end)}';
      default:
        return 'Todos os meses';
    }
  }

  bool _dentroDoPeriodo(DateTime data) {
    final agora = DateTime.now();
    final dia = DateTime(data.year, data.month, data.day);
    switch (_periodo) {
      case 'este_mes':
        return dia.year == agora.year && dia.month == agora.month;
      case 'mes_passado':
        final mesPassado = DateTime(agora.year, agora.month - 1);
        return dia.year == mesPassado.year && dia.month == mesPassado.month;
      case 'personalizado':
        if (_intervaloPersonalizado == null) return true;
        final inicio = _intervaloPersonalizado!.start;
        final fim = _intervaloPersonalizado!.end;
        return !dia.isBefore(DateTime(inicio.year, inicio.month, inicio.day)) &&
            !dia.isAfter(DateTime(fim.year, fim.month, fim.day));
      default:
        return true;
    }
  }

  List<Object> _agruparPorMes(List<_Item> itens) {
    final resultado = <Object>[];
    int? anoAtual;
    int? mesAtual;
    for (final item in itens) {
      if (item.data.year != anoAtual || item.data.month != mesAtual) {
        anoAtual = item.data.year;
        mesAtual = item.data.month;
        resultado.add(
          '${_nomesMesesCompletos[item.data.month - 1]} DE ${item.data.year}'
              .toUpperCase(),
        );
      }
      resultado.add(item);
    }
    return resultado;
  }

  Future<void> _exportarRelatorio(List<_Item> itens) async {
    final entradas = itens
        .where((i) => i.tipo == 'entrada')
        .fold<double>(0, (soma, i) => soma + i.valor);
    final saidas = itens
        .where((i) => i.tipo == 'saida')
        .fold<double>(0, (soma, i) => soma + i.valor);
    final agora = DateTime.now();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'SPOKFIN',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Relatório de Lançamentos',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Gerado em ${formatarData(agora)}'),
          if (!_temMais)
            pw.Text(
              'Obs: relatório considera apenas os lançamentos já carregados na tela.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Data', 'Descrição', 'Categoria', 'Status', 'Valor'],
            data: [
              for (final i in itens)
                [
                  formatarData(i.data),
                  i.descricao,
                  i.categoria,
                  i.statusLabel,
                  '${i.tipo == 'entrada' ? '+' : '-'} ${formatarMoeda(i.valor)}',
                ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text('Total de Entradas: ${formatarMoeda(entradas)}'),
          pw.Text('Total de Saídas: ${formatarMoeda(saidas)}'),
          pw.Text(
            'Saldo do Período: ${formatarMoeda(entradas - saidas)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: _nomeArquivoRelatorio(),
    );
  }

  String _nomeArquivoRelatorio() {
    final rotulo = _rotuloPeriodo()
        .replaceAll('/', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return 'Relatorio Spokfin - $rotulo.pdf';
  }

  Future<void> _abrirDetalhes(_Item item) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Contas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: supabase.auth.signOut,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_erro != null) {
            return Center(child: Text('Erro: $_erro'));
          }
          if (_itens == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final busca = _buscaController.text.trim().toLowerCase();
          final itens = _itens!.where((i) {
            final passaFiltro =
                _filtro == 'tudo' ||
                (_filtro == 'entradas' && i.tipo == 'entrada') ||
                (_filtro == 'saidas' && i.tipo == 'saida');
            final passaBusca =
                busca.isEmpty || i.descricao.toLowerCase().contains(busca);
            return passaFiltro && passaBusca && _dentroDoPeriodo(i.data);
          }).toList();
          final agrupado = _agruparPorMes(itens);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _buscaController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar lançamentos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FiltroChip(
                      label: 'Tudo',
                      selecionado: _filtro == 'tudo',
                      onTap: () => setState(() => _filtro = 'tudo'),
                    ),
                    const SizedBox(width: 8),
                    _FiltroChip(
                      label: 'Entradas',
                      selecionado: _filtro == 'entradas',
                      onTap: () => setState(() => _filtro = 'entradas'),
                    ),
                    const SizedBox(width: 8),
                    _FiltroChip(
                      label: 'Saídas',
                      selecionado: _filtro == 'saidas',
                      onTap: () => setState(() => _filtro = 'saidas'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _abrirSeletorPeriodo,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _rotuloPeriodo(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: itens.isEmpty
                          ? null
                          : () => _exportarRelatorio(itens),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Exportar período'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: itens.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum lançamento encontrado',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: agrupado.length + (_temMais ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == agrupado.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Center(
                                child: _carregandoMais
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _carregarMais,
                                        child: const Text('Carregar mais'),
                                      ),
                              ),
                            );
                          }
                          final entrada = agrupado[i];
                          if (entrada is String) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : 20,
                                bottom: 8,
                              ),
                              child: RotuloCard(
                                entrada,
                                letterSpacing: 1,
                                negrito: true,
                              ),
                            );
                          }
                          final item = entrada as _Item;
                          return _ItemTile(
                            item: item,
                            onTap: () => _abrirDetalhes(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaginaHistorico {
  _PaginaHistorico({required this.itens, required this.temMais});

  final List<_Item> itens;
  final bool temMais;
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: TextStyle(
        color: selecionado ? AppColors.background : AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
      side: selecionado
          ? BorderSide.none
          : const BorderSide(color: AppColors.hairline),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap});

  final _Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positivo = item.tipo == 'entrada';
    final cor = positivo ? AppColors.accent : AppColors.negative;
    final sinal = positivo ? '+' : '-';
    final subtitulo = [
      formatarData(item.data),
      if (item.categoria.isNotEmpty) item.categoria,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Icon(
              item.statusLabel == 'Pago'
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: item.statusLabel == 'Pago'
                  ? AppColors.accent
                  : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.notaFiscalStatus == 'pendente') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: AppColors.accent),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'NFC-e agendada',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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
