import 'package:flutter/material.dart';

import '../main.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key, required this.empresaId, this.cliente});

  final String empresaId;
  final Map<String, dynamic>? cliente;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  bool _loading = false;
  String? _error;

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.cliente?['nome'] as String? ?? '',
    );
    _telefoneController = TextEditingController(
      text: widget.cliente?['telefone'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
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
      final dados = {
        'nome': nome,
        'telefone': _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Cliente' : 'Novo Cliente'),
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
                          _editando ? 'Salvar Alterações' : 'Salvar Cliente',
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
