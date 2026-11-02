import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../shared/lancamentos_bus.dart';
import '../shared/tilt_depth.dart';
import '../theme.dart';
import 'categorias.dart';
import 'ia_service.dart';

class RevisarLancamentoScreen extends StatefulWidget {
  const RevisarLancamentoScreen({
    super.key,
    required this.empresaId,
    required this.lancamento,
  });

  final String empresaId;
  final LancamentoExtraido lancamento;

  @override
  State<RevisarLancamentoScreen> createState() =>
      _RevisarLancamentoScreenState();
}

class _RevisarLancamentoScreenState extends State<RevisarLancamentoScreen> {
  late String _tipo;
  late String _status;
  late bool _querNotaFiscal;
  late String _categoria;
  late DateTime _data;
  String? _clienteId;
  late final TextEditingController _valorController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _novaCategoriaController;
  late List<String> _categorias;
  late Future<List<Map<String, dynamic>>> _contatosFuture;
  bool _loading = false;
  String? _error;

  bool get _ehGasto => _tipo == 'saida';
  String get _tipoContato => _ehGasto ? 'fornecedor' : 'cliente';
  List<String> get _categoriasBase =>
      _ehGasto ? categoriasDespesa : categoriasReceita;

  @override
  void initState() {
    super.initState();
    _tipo = widget.lancamento.tipo;
    _status = widget.lancamento.status;
    _querNotaFiscal = widget.lancamento.querNotaFiscal;
    _categoria = widget.lancamento.categoria;
    _data = widget.lancamento.data;
    _valorController = TextEditingController(
      text: widget.lancamento.valor > 0
          ? _formatarValor(widget.lancamento.valor)
          : '',
    );
    _descricaoController = TextEditingController(
      text: widget.lancamento.descricao,
    );
    _novaCategoriaController = TextEditingController();
    _categorias = [
      ..._categoriasBase,
      if (_categoria.isNotEmpty && !_categoriasBase.contains(_categoria))
        _categoria,
    ];
    _contatosFuture = _carregarContatos();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    _novaCategoriaController.dispose();
    super.dispose();
  }

  String _formatarValor(double v) {
    return v.truncateToDouble() == v
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
  }

  double _valorAtual() {
    final texto = _valorController.text.replaceAll(',', '.').trim();
    return double.tryParse(texto) ?? 0;
  }

  Future<List<Map<String, dynamic>>> _carregarContatos() async {
    final rows = await supabase
        .from('clientes')
        .select('id, nome')
        .eq('empresa_id', widget.empresaId)
        .eq('ativo', true)
        .eq('tipo', _tipoContato)
        .order('nome');
    final contatos = List<Map<String, dynamic>>.from(rows);

    final nomeAlvoBruto = widget.lancamento.clienteNome?.trim();
    if (nomeAlvoBruto != null && nomeAlvoBruto.isNotEmpty) {
      final nomeAlvo = normalizarNome(nomeAlvoBruto);
      for (final c in contatos) {
        final nome = normalizarNome(c['nome'] as String);
        if (nome.contains(nomeAlvo) || nomeAlvo.contains(nome)) {
          _clienteId = c['id'] as String;
          break;
        }
      }
    }
    return contatos;
  }

  void _mudarTipo(String novoTipo) {
    setState(() {
      _tipo = novoTipo;
      _clienteId = null;
      _contatosFuture = _carregarContatos();
      _categorias = [..._categoriasBase];
      _categoria = _categorias.first;
    });
  }

  void _adicionarValor(double incremento) {
    final novo = _valorAtual() + incremento;
    setState(() {
      _valorController.text = _formatarValor(novo);
    });
  }

  void _usarNovaCategoria() {
    final nova = _novaCategoriaController.text.trim();
    if (nova.isEmpty) return;
    setState(() {
      if (!_categorias.contains(nova)) _categorias.add(nova);
      _categoria = nova;
      _novaCategoriaController.clear();
    });
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(_data.year - 2),
      lastDate: DateTime(_data.year + 2),
      cancelText: 'Cancelar',
      confirmText: 'Usar',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _cadastrarContato() async {
    final rotulo = _ehGasto ? 'fornecedor' : 'cliente';
    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Novo $rotulo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: 'Nome do $rotulo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (nome == null || nome.isEmpty) return;
    try {
      final row = await supabase
          .from('clientes')
          .insert({
            'empresa_id': widget.empresaId,
            'nome': nome,
            'tipo': _tipoContato,
          })
          .select('id, nome')
          .single();
      setState(() {
        _clienteId = row['id'] as String;
        _contatosFuture = _carregarContatos();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar $rotulo: $e')));
      }
    }
  }

  Future<void> _salvar() async {
    final valor = _valorAtual();
    if (valor <= 0) {
      setState(() => _error = 'Informe um valor');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dataIso = formatarDataIso(_data);
      final notaFiscalStatus = _querNotaFiscal ? 'pendente' : 'nao_aplicavel';
      if (_status == 'pago') {
        await supabase.from('transacoes').insert({
          'empresa_id': widget.empresaId,
          'tipo': _tipo,
          'categoria': _categoria,
          'descricao': _descricaoController.text.trim(),
          'valor': valor,
          'nota_fiscal_status': notaFiscalStatus,
          'cliente_id': _clienteId,
          'data_transacao': dataIso,
        });
      } else {
        await supabase.from('contas_pagar_receber').insert({
          'empresa_id': widget.empresaId,
          'tipo': _tipo == 'entrada' ? 'receber' : 'pagar',
          'descricao': _descricaoController.text.trim(),
          'categoria': _categoria,
          'valor': valor,
          'vencimento': dataIso,
          'nota_fiscal_status': notaFiscalStatus,
          'cliente_id': _clienteId,
        });
      }
      notificarLancamentosAtualizados();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotuloData = _status == 'pendente' ? 'DATA DE VENCIMENTO' : 'DATA';
    final rotuloContato = _ehGasto ? 'FORNECEDOR' : 'CLIENTE';
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Lançamento')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCard('VALOR'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          prefixText: 'R\$ ',
                          prefixStyle: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          hintText: '0',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipAcao(
                            label: '+ R\$ 10',
                            onTap: () => _adicionarValor(10),
                          ),
                          _ChipAcao(
                            label: '+ R\$ 50',
                            onTap: () => _adicionarValor(50),
                          ),
                          _ChipAcao(
                            label: '+ R\$ 100',
                            onTap: () => _adicionarValor(100),
                          ),
                          _ChipAcao(
                            label: 'Zerar',
                            onTap: () =>
                                setState(() => _valorController.text = ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCard('DESCRIÇÃO'),
                      TextField(
                        controller: _descricaoController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.only(top: 4),
                          hintText: 'O que aconteceu?',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCard('TIPO'),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'entrada',
                            label: Text('Entrada (Receber)'),
                          ),
                          ButtonSegment(
                            value: 'saida',
                            label: Text('Saída (Pagar)'),
                          ),
                        ],
                        selected: {_tipo},
                        onSelectionChanged: (s) => _mudarTipo(s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCard('STATUS'),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'pago', label: Text('Pago')),
                          ButtonSegment(
                            value: 'pendente',
                            label: Text('Pendente'),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (s) =>
                            setState(() => _status = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCard('CATEGORIA'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _categorias)
                            ChoiceChip(
                              label: Text(c),
                              selected: _categoria == c,
                              onSelected: (_) => setState(() => _categoria = c),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: _categoria == c
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _novaCategoriaController,
                              decoration: const InputDecoration(
                                hintText: 'Ou digite uma nova categoria',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _usarNovaCategoria,
                            child: const Text('Usar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RotuloCard(rotuloContato),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _contatosFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const LinearProgressIndicator();
                          }
                          final contatos = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: _clienteId,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            dropdownColor: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            style: const TextStyle(color: AppColors.textPrimary),
                            hint: Text(
                              _ehGasto
                                  ? 'Sem fornecedor vinculado'
                                  : 'Sem cliente vinculado',
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  _ehGasto
                                      ? 'Sem fornecedor vinculado'
                                      : 'Sem cliente vinculado',
                                  style: TextStyle(
                                    color: _clienteId == null
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: _clienteId == null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              for (final c in contatos)
                                DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(
                                    c['nome'] as String,
                                    style: TextStyle(
                                      color: _clienteId == c['id']
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: _clienteId == c['id']
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _clienteId = v),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _cadastrarContato,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            _ehGasto
                                ? 'Cadastrar novo fornecedor'
                                : 'Cadastrar novo cliente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: InkWell(
                    onTap: _escolherData,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RotuloCard(rotuloData),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatarData(_data),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Emitir Nota Fiscal (NFC-e)?'),
                    subtitle: const Text(
                      'Só sinaliza — a emissão é feita por fora',
                    ),
                    value: _querNotaFiscal,
                    onChanged: (v) => setState(() => _querNotaFiscal = v),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TiltDepth(
                  maxAngle: 0.04,
                  child: FilledButton(
                    onPressed: _loading ? null : _salvar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar Lançamento'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipAcao extends StatelessWidget {
  const _ChipAcao({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      side: BorderSide.none,
    );
  }
}
