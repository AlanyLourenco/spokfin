import 'dart:ui';

import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'lancamento_detalhado.dart';
import 'recibo_dialog.dart';

const _categoriasPadrao = [
  'Venda',
  'Empréstimo',
  'Aula',
  'Consultoria',
  'Serviço',
  'Outros',
];

/// Abre os Detalhes de um lançamento como um modal deslizante de baixo pra
/// cima, com fundo desfocado — pode transicionar internamente pro estado de
/// edição sem fechar/reabrir o modal. Retorna `true` se algo mudou (o
/// chamador deve recarregar sua lista).
Future<bool?> mostrarDetalhesLancamento(
  BuildContext context, {
  required String empresaId,
  required LancamentoDetalhado lancamento,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'Detalhes do Lançamento',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: _LancamentoModal(
          empresaId: empresaId,
          lancamentoInicial: lancamento,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6 * animation.value,
          sigmaY: 6 * animation.value,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}

class _LancamentoModal extends StatefulWidget {
  const _LancamentoModal({
    required this.empresaId,
    required this.lancamentoInicial,
  });

  final String empresaId;
  final LancamentoDetalhado lancamentoInicial;

  @override
  State<_LancamentoModal> createState() => _LancamentoModalState();
}

class _LancamentoModalState extends State<_LancamentoModal> {
  late LancamentoDetalhado _lancamento;
  bool _editando = false;
  bool _loading = false;
  bool _alterou = false;

  // Estado do formulário de edição — só populado ao entrar em modo edição.
  late final TextEditingController _descricaoController;
  late final TextEditingController _novaCategoriaController;
  late final TextEditingController _valorController;
  late String _tipo;
  late String _status;
  late String _categoria;
  late DateTime _data;
  String? _clienteId;
  late List<String> _categorias;
  Future<List<Map<String, dynamic>>>? _clientesFuture;

  bool get _pago => _lancamento.status == 'pago';
  bool get _entrada => _lancamento.tipo == 'entrada';
  bool get _notaFiscalPendente => _lancamento.notaFiscalStatus == 'pendente';

  @override
  void initState() {
    super.initState();
    _lancamento = widget.lancamentoInicial;
    _descricaoController = TextEditingController();
    _novaCategoriaController = TextEditingController();
    _valorController = TextEditingController();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _novaCategoriaController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _fechar() => Navigator.of(context).pop(_alterou);

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Erro: $e')));
  }

  Future<List<Map<String, dynamic>>> _carregarClientes() async {
    final rows = await supabase
        .from('clientes')
        .select('id, nome')
        .eq('empresa_id', widget.empresaId)
        .eq('ativo', true)
        .order('nome');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _marcarPago() async {
    setState(() => _loading = true);
    try {
      await supabase.rpc(
        'registrar_pagamento',
        params: {'p_conta_id': _lancamento.id},
      );
      _alterou = true;
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
      _alterou = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      _alterou = true;
      setState(
        () => _lancamento = _lancamento.copiarCom(notaFiscalStatus: 'emitida'),
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
          'Isso vai apagar "${_lancamento.descricao}" (${formatarValorCifrao(_lancamento.valor)}) permanentemente. Essa ação não pode ser desfeita.',
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
    if (confirmou != true) return;

    setState(() => _loading = true);
    try {
      final tabela = _lancamento.origem == 'transacao'
          ? 'transacoes'
          : 'contas_pagar_receber';
      await supabase.from(tabela).delete().eq('id', _lancamento.id);
      _alterou = true;
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

  void _entrarModoEdicao() {
    _descricaoController.text = _lancamento.descricao;
    _novaCategoriaController.clear();
    _valorController.text = _formatarValorEdicao(_lancamento.valor);
    _tipo = _lancamento.tipo;
    _status = _lancamento.status == 'atrasado' ? 'pendente' : _lancamento.status;
    _categoria = _lancamento.categoria;
    _data = _lancamento.data;
    _clienteId = _lancamento.clienteId;
    _categorias = [
      ..._categoriasPadrao,
      if (_categoria.isNotEmpty && !_categoriasPadrao.contains(_categoria))
        _categoria,
    ];
    _clientesFuture = _carregarClientes();
    setState(() => _editando = true);
  }

  String _formatarValorEdicao(double v) {
    return v.truncateToDouble() == v
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
  }

  double _valorEdicaoAtual() {
    final texto = _valorController.text.replaceAll(',', '.').trim();
    return double.tryParse(texto) ?? 0;
  }

  void _adicionarValorEdicao(double incremento) {
    final novo = _valorEdicaoAtual() + incremento;
    setState(() => _valorController.text = _formatarValorEdicao(novo));
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

  Future<void> _salvarEdicao() async {
    final valor = _valorEdicaoAtual();
    if (valor <= 0) {
      _mostrarErro('Informe um valor');
      return;
    }

    setState(() => _loading = true);
    try {
      final dataIso =
          '${_data.year.toString().padLeft(4, '0')}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';
      await supabase.rpc(
        'atualizar_lancamento',
        params: {
          'p_id': _lancamento.id,
          'p_origem': _lancamento.origem,
          'p_novo_status': _status,
          'p_descricao': _descricaoController.text.trim(),
          'p_categoria': _categoria,
          'p_valor': valor,
          'p_tipo': _tipo,
          'p_cliente_id': _clienteId,
          'p_data': dataIso,
        },
      );
      _alterou = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.hairline),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editando
                            ? 'Editar Lançamento'
                            : 'Detalhes do Lançamento',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (!_editando) ...[
                      _CircularIconButton(
                        icon: Icons.edit_outlined,
                        onTap: _loading ? null : _entrarModoEdicao,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _CircularIconButton(
                      icon: Icons.close,
                      onTap: _loading ? null : _fechar,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.hairline, height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _editando ? _buildEditBody() : _buildViewBody(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _editando ? _buildEditFooter() : _buildViewFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewBody() {
    final positivo = _entrada;
    final cor = positivo ? AppColors.accent : AppColors.negative;
    final sinal = positivo ? '+' : '-';
    final statusLabel = _pago
        ? 'Pago'
        : (_lancamento.status == 'atrasado' ? 'Atrasado' : 'Pendente');
    final statusCor = _pago
        ? AppColors.accent
        : (_lancamento.status == 'atrasado'
              ? AppColors.negative
              : const Color(0xFFF5A623));

    return Column(
      key: const ValueKey('view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _lancamento.categoria.isEmpty ? '—' : _lancamento.categoria,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          _lancamento.descricao,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$sinal ${formatarValorCifrao(_lancamento.valor)}',
          style: TextStyle(color: cor, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _InfoBox(
                label: 'DATA',
                valor: _formatarData(_lancamento.data),
                corValor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoBox(
                label: 'STATUS',
                valor: statusLabel,
                corValor: statusCor,
              ),
            ),
          ],
        ),
        if (_lancamento.clienteNome != null) ...[
          const SizedBox(height: 12),
          _InfoBox(
            label: 'CLIENTE',
            valor: _lancamento.clienteNome!,
            corValor: AppColors.textPrimary,
          ),
        ],
        if (_lancamento.notaFiscalStatus != 'nao_aplicavel') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
            ),
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
                    _notaFiscalPendente ? 'NFC-e agendada' : 'NFC-e emitida',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                if (_notaFiscalPendente)
                  TextButton(
                    onPressed: _loading ? null : _marcarNotaFiscalEmitida,
                    child: const Text('Marcar como emitida'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _loading ? null : _confirmarExclusao,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.negative,
            side: const BorderSide(color: AppColors.negative),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Excluir Lançamento'),
        ),
      ],
    );
  }

  Widget _buildViewFooter() {
    final botaoStatus = Expanded(
      child: OutlinedButton(
        onPressed: _loading ? null : (_pago ? _marcarPendente : _marcarPago),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_pago ? 'Marcar Pendente' : 'Marcar Pago'),
      ),
    );

    if (!(_pago && _entrada)) return Row(children: [botaoStatus]);

    return Row(
      children: [
        botaoStatus,
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _gerarRecibo,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Gerar Recibo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBody() {
    return Column(
      key: const ValueKey('edit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSection(
          label: 'DESCRIÇÃO',
          child: TextField(
            controller: _descricaoController,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _formSection(
          label: 'VALOR',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _PillChip(
                    label: '+ R\$ 10',
                    onTap: () => _adicionarValorEdicao(10),
                  ),
                  _PillChip(
                    label: '+ R\$ 50',
                    onTap: () => _adicionarValorEdicao(50),
                  ),
                  _PillChip(
                    label: '+ R\$ 100',
                    onTap: () => _adicionarValorEdicao(100),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _formSection(
          label: 'TIPO',
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'entrada', label: Text('Ganho')),
              ButtonSegment(value: 'saida', label: Text('Gasto')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
        ),
        const SizedBox(height: 12),
        _formSection(
          label: 'STATUS',
          child: SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              foregroundColor: AppColors.textMuted,
              selectedBackgroundColor: Colors.white,
              selectedForegroundColor: AppColors.background,
            ),
            segments: const [
              ButtonSegment(value: 'pago', label: Text('Pago')),
              ButtonSegment(value: 'pendente', label: Text('Pendente')),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
        ),
        const SizedBox(height: 12),
        _formSection(
          label: 'CATEGORIA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _novaCategoriaController,
                      style: const TextStyle(color: AppColors.textPrimary),
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
        _formSection(
          label: 'CLIENTE',
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _clientesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              final clientes = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _clienteId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                dropdownColor: AppColors.surfaceAlt,
                style: const TextStyle(color: AppColors.textPrimary),
                hint: const Text(
                  'Sem cliente vinculado',
                  style: TextStyle(color: AppColors.textMuted),
                ),
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
        ),
        const SizedBox(height: 12),
        _formSection(
          label: 'DATA',
          child: InkWell(
            onTap: _escolherData,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatarData(_data),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
          ),
        ),
      ],
    );
  }

  Widget _formSection({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildEditFooter() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : () => setState(() => _editando = false),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _loading ? null : _salvarEdicao,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 17, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.valor,
    required this.corValor,
  });

  final String label;
  final String valor;
  final Color corValor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: corValor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      side: BorderSide.none,
    );
  }
}

String _formatarData(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
