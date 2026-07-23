import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../theme.dart';
import 'lancamento_detalhado.dart';

const _categoriasPadrao = [
  'Venda',
  'Empréstimo',
  'Aula',
  'Consultoria',
  'Serviço',
  'Outros',
];

class EditarLancamentoScreen extends StatefulWidget {
  const EditarLancamentoScreen({
    super.key,
    required this.empresaId,
    required this.lancamento,
  });

  final String empresaId;
  final LancamentoDetalhado lancamento;

  @override
  State<EditarLancamentoScreen> createState() => _EditarLancamentoScreenState();
}

class _EditarLancamentoScreenState extends State<EditarLancamentoScreen> {
  late final TextEditingController _descricaoController;
  late final TextEditingController _novaCategoriaController;
  late String _tipo;
  late String _status;
  late double _valor;
  late String _categoria;
  late DateTime _data;
  String? _clienteId;
  late final List<String> _categorias;
  late Future<List<Map<String, dynamic>>> _clientesFuture;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(
      text: widget.lancamento.descricao,
    );
    _novaCategoriaController = TextEditingController();
    _tipo = widget.lancamento.tipo;
    _status = widget.lancamento.status == 'atrasado'
        ? 'pendente'
        : widget.lancamento.status;
    _valor = widget.lancamento.valor;
    _categoria = widget.lancamento.categoria;
    _data = widget.lancamento.data;
    _clienteId = widget.lancamento.clienteId;
    _categorias = [
      ..._categoriasPadrao,
      if (_categoria.isNotEmpty && !_categoriasPadrao.contains(_categoria))
        _categoria,
    ];
    _clientesFuture = _carregarClientes();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _novaCategoriaController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _carregarClientes() async {
    final rows = await supabase
        .from('clientes')
        .select('id, nome')
        .eq('empresa_id', widget.empresaId)
        .order('nome');
    return List<Map<String, dynamic>>.from(rows);
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

  Future<void> _salvar() async {
    if (_valor <= 0) {
      setState(() => _error = 'Informe um valor');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dataIso =
          '${_data.year.toString().padLeft(4, '0')}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';
      await supabase.rpc(
        'atualizar_lancamento',
        params: {
          'p_id': widget.lancamento.id,
          'p_origem': widget.lancamento.origem,
          'p_novo_status': _status,
          'p_descricao': _descricaoController.text.trim(),
          'p_categoria': _categoria,
          'p_valor': _valor,
          'p_tipo': _tipo,
          'p_cliente_id': _clienteId,
          'p_data': dataIso,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Lançamento'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
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
                      const Text(
                        'DESCRIÇÃO',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      TextField(
                        controller: _descricaoController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.only(top: 4),
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
                      const Text(
                        'VALOR',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${_valor.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipAcao(
                            label: '+ R\$ 10',
                            onTap: () => setState(() => _valor += 10),
                          ),
                          _ChipAcao(
                            label: '+ R\$ 50',
                            onTap: () => setState(() => _valor += 50),
                          ),
                          _ChipAcao(
                            label: '+ R\$ 100',
                            onTap: () => setState(() => _valor += 100),
                          ),
                          _ChipAcao(
                            label: 'Zerar',
                            onTap: () => setState(() => _valor = 0),
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
                      const Text(
                        'TIPO',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'entrada', label: Text('Ganho')),
                          ButtonSegment(value: 'saida', label: Text('Gasto')),
                        ],
                        selected: {_tipo},
                        onSelectionChanged: (s) =>
                            setState(() => _tipo = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
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
                      const Text(
                        'CATEGORIA',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
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
                              selectedColor: AppColors.accent,
                              backgroundColor: AppColors.surfaceAlt,
                              labelStyle: TextStyle(
                                color: _categoria == c
                                    ? Colors.black
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
                      const Text(
                        'CLIENTE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _clientesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const LinearProgressIndicator();
                          }
                          final clientes = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: _clienteId,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            dropdownColor: AppColors.surfaceAlt,
                            hint: const Text('Sem cliente vinculado'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Sem cliente vinculado'),
                              ),
                              for (final c in clientes)
                                DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(c['nome'] as String),
                                ),
                            ],
                            onChanged: (v) => setState(() => _clienteId = v),
                          );
                        },
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
                        const Text(
                          'DATA',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatarData(_data),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : _salvar,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
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

String _formatarData(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      side: BorderSide.none,
    );
  }
}
