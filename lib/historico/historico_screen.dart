import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../lancamentos/detalhes_lancamento_screen.dart';
import '../lancamentos/lancamento_detalhado.dart';
import '../main.dart';
import '../theme.dart';

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
  late Future<List<_Item>> _future;
  String _filtro = 'tudo';
  String _periodo = 'todos';
  DateTimeRange? _intervaloPersonalizado;
  final _buscaController = TextEditingController();

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

  String _formatarDataCurta(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
          pw.Text('Gerado em ${_formatarDataExtenso(agora)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Data', 'Descrição', 'Categoria', 'Status', 'Valor'],
            data: [
              for (final i in itens)
                [
                  _formatarDataExtenso(i.data),
                  i.descricao,
                  i.categoria,
                  i.statusLabel,
                  '${i.tipo == 'entrada' ? '+' : '-'} R\$ ${i.valor.toStringAsFixed(2)}',
                ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text('Total de Entradas: R\$ ${entradas.toStringAsFixed(2)}'),
          pw.Text('Total de Saídas: R\$ ${saidas.toStringAsFixed(2)}'),
          pw.Text(
            'Saldo do Período: R\$ ${(entradas - saidas).toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'relatorio_lancamentos.pdf',
    );
  }

  String _formatarDataExtenso(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  Future<List<_Item>> _carregar() async {
    final transacoes = await supabase
        .from('transacoes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .order('data_transacao', ascending: false);

    final contas = await supabase
        .from('contas_pagar_receber_vw')
        .select()
        .eq('empresa_id', widget.empresaId)
        .neq('status_efetivo', 'pago')
        .order('vencimento', ascending: false);

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

    return itens;
  }

  Future<void> _abrirDetalhes(_Item item) async {
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

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
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
      body: FutureBuilder<List<_Item>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final busca = _buscaController.text.trim().toLowerCase();
          final itens = snapshot.data!.where((i) {
            final passaFiltro =
                _filtro == 'tudo' ||
                (_filtro == 'entradas' && i.tipo == 'entrada') ||
                (_filtro == 'saidas' && i.tipo == 'saida');
            final passaBusca =
                busca.isEmpty || i.descricao.toLowerCase().contains(busca);
            return passaFiltro && passaBusca && _dentroDoPeriodo(i.data);
          }).toList();

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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        selecionado: _periodo == 'todos',
                        onTap: () => setState(() => _periodo = 'todos'),
                      ),
                      const SizedBox(width: 8),
                      _FiltroChip(
                        label: 'Este Mês',
                        selecionado: _periodo == 'este_mes',
                        onTap: () => setState(() => _periodo = 'este_mes'),
                      ),
                      const SizedBox(width: 8),
                      _FiltroChip(
                        label: 'Mês Passado',
                        selecionado: _periodo == 'mes_passado',
                        onTap: () => setState(() => _periodo = 'mes_passado'),
                      ),
                      const SizedBox(width: 8),
                      _FiltroChip(
                        label: _intervaloPersonalizado == null
                            ? 'Personalizado'
                            : '${_formatarDataCurta(_intervaloPersonalizado!.start)} - ${_formatarDataCurta(_intervaloPersonalizado!.end)}',
                        selecionado: _periodo == 'personalizado',
                        onTap: _escolherPeriodoPersonalizado,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: itens.isEmpty
                        ? null
                        : () => _exportarRelatorio(itens),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Exportar período'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: itens.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum lançamento encontrado',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: itens.length,
                        itemBuilder: (context, i) => _ItemTile(
                          item: itens[i],
                          onTap: () => _abrirDetalhes(itens[i]),
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
        color: selecionado ? Colors.black : AppColors.textMuted,
      ),
      side: BorderSide.none,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
                  Text(item.descricao),
                  Text(
                    [
                      if (item.categoria.isNotEmpty) item.categoria,
                      item.statusLabel,
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sinal R\$ ${item.valor.toStringAsFixed(2)}',
              style: TextStyle(color: cor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
