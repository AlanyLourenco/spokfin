import 'package:flutter/material.dart';

import '../main.dart';

const _tiposChavePix = {
  'cpf_cnpj': 'CPF/CNPJ',
  'email': 'E-mail',
  'telefone': 'Telefone',
  'aleatoria': 'Chave Aleatória',
};

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({
    super.key,
    required this.empresaId,
    this.cliente,
    this.tipo = 'cliente',
  });

  final String empresaId;
  final Map<String, dynamic>? cliente;

  /// 'cliente' ou 'fornecedor' — só usado ao criar um novo registro; ao
  /// editar, o tipo já vem de [cliente] e não muda.
  final String tipo;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _chavePixController;
  String? _tipoChavePix;
  bool _loading = false;
  String? _error;

  bool get _editando => widget.cliente != null;
  String get _tipo => widget.cliente?['tipo'] as String? ?? widget.tipo;
  bool get _ehFornecedor => _tipo == 'fornecedor';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.cliente?['nome'] as String? ?? '',
    );
    _telefoneController = TextEditingController(
      text: widget.cliente?['telefone'] as String? ?? '',
    );
    _chavePixController = TextEditingController(
      text: widget.cliente?['chave_pix'] as String? ?? '',
    );
    _tipoChavePix = widget.cliente?['tipo_chave_pix'] as String?;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _chavePixController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Nome é obrigatório');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chavePix = _chavePixController.text.trim();
      final dados = {
        'nome': nome,
        'telefone': _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        if (_ehFornecedor) 'chave_pix': chavePix.isEmpty ? null : chavePix,
        if (_ehFornecedor) 'tipo_chave_pix': chavePix.isEmpty ? null : _tipoChavePix,
      };
      if (_editando) {
        await supabase
            .from('clientes')
            .update(dados)
            .eq('id', widget.cliente!['id'] as String);
      } else {
        await supabase.from('clientes').insert({
          ...dados,
          'empresa_id': widget.empresaId,
          'tipo': widget.tipo,
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotulo = _ehFornecedor ? 'Fornecedor' : 'Cliente';
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar $rotulo' : 'Novo $rotulo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome / Empresa',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(labelText: 'Número'),
                  keyboardType: TextInputType.phone,
                ),
                if (_ehFornecedor) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chavePixController,
                    decoration: const InputDecoration(
                      labelText: 'Chave PIX do Fornecedor (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoChavePix,
                    decoration: const InputDecoration(
                      labelText: 'Tipo da Chave',
                    ),
                    hint: const Text('Selecione o tipo'),
                    items: [
                      for (final entrada in _tiposChavePix.entries)
                        DropdownMenuItem(
                          value: entrada.key,
                          child: Text(entrada.value),
                        ),
                    ],
                    onChanged: (v) => setState(() => _tipoChavePix = v),
                  ),
                ],
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
                FilledButton(
                  onPressed: _loading ? null : _salvar,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _editando
                              ? 'Salvar Alterações'
                              : 'Salvar $rotulo',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
