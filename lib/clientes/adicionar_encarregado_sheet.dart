import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/campo_rotulado.dart';
import '../shared/mascaras.dart';
import '../theme.dart';

Future<bool?> mostrarFormularioEncarregado(
  BuildContext context, {
  required String empresaId,
  required String clienteId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _FormularioEncarregado(empresaId: empresaId, clienteId: clienteId),
    ),
  );
}

class _FormularioEncarregado extends StatefulWidget {
  const _FormularioEncarregado({
    required this.empresaId,
    required this.clienteId,
  });

  final String empresaId;
  final String clienteId;

  @override
  State<_FormularioEncarregado> createState() => _FormularioEncarregadoState();
}

class _FormularioEncarregadoState extends State<_FormularioEncarregado> {
  final _nomeController = TextEditingController();
  final _cargoController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Nome é obrigatório');
      return;
    }
    final telefone = _telefoneController.text.trim();
    if (telefone.isNotEmpty && !telefoneValido(telefone)) {
      setState(() => _error = 'Telefone inválido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.from('encarregados').insert({
        'empresa_id': widget.empresaId,
        'cliente_id': widget.clienteId,
        'nome': nome,
        'cargo': _cargoController.text.trim().isEmpty
            ? null
            : _cargoController.text.trim(),
        'telefone': _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Adicionar Encarregado',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        CampoRotulado(
          rotulo: 'Nome',
          child: TextField(
            controller: _nomeController,
            decoration: const InputDecoration(hintText: 'Nome do encarregado'),
          ),
        ),
        const SizedBox(height: 16),
        CampoRotulado(
          rotulo: 'Cargo (opcional)',
          child: TextField(
            controller: _cargoController,
            decoration: const InputDecoration(hintText: 'Ex: Financeiro'),
          ),
        ),
        const SizedBox(height: 16),
        CampoRotulado(
          rotulo: 'Telefone (opcional)',
          child: TextField(
            controller: _telefoneController,
            decoration: const InputDecoration(hintText: '(00) 00000-0000'),
            keyboardType: TextInputType.phone,
            inputFormatters: [TelefoneInputFormatter()],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}
