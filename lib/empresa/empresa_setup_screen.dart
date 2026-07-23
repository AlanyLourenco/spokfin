import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../shared/campo_rotulado.dart';
import '../shared/mascaras.dart';

class EmpresaSetupScreen extends StatefulWidget {
  const EmpresaSetupScreen({super.key, required this.onEmpresaCriada});

  final VoidCallback onEmpresaCriada;

  @override
  State<EmpresaSetupScreen> createState() => _EmpresaSetupScreenState();
}

class _EmpresaSetupScreenState extends State<EmpresaSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cnpjController = TextEditingController();
  final _cpfController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cnpjController.dispose();
    _cpfController.dispose();
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.from('empresas').insert({
        'owner_id': supabase.auth.currentUser!.id,
        'cnpj': _cnpjController.text.trim().isEmpty
            ? null
            : _cnpjController.text.trim(),
        'cpf': _cpfController.text.trim().isEmpty
            ? null
            : _cpfController.text.trim(),
        'razao_social': _razaoSocialController.text.trim(),
        'nome_fantasia': _nomeFantasiaController.text.trim().isEmpty
            ? null
            : _nomeFantasiaController.text.trim(),
      });
      widget.onEmpresaCriada();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar empresa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: supabase.auth.signOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dê um nome pra sua empresa para continuar. CNPJ, CPF e os demais dados são opcionais e podem ser preenchidos depois.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CampoRotulado(
                    rotulo: 'Nome da Empresa',
                    child: TextFormField(
                      controller: _razaoSocialController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Padaria do João',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CampoRotulado(
                    rotulo: 'Nome fantasia (opcional)',
                    child: TextFormField(
                      controller: _nomeFantasiaController,
                      decoration: const InputDecoration(
                        hintText: 'Como o cliente te conhece',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CampoRotulado(
                    rotulo: 'CNPJ (opcional)',
                    child: TextFormField(
                      controller: _cnpjController,
                      decoration: const InputDecoration(
                        hintText: '00.000.000/0000-00',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CpfCnpjInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return cnpjValido(v) ? null : 'CNPJ inválido';
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CampoRotulado(
                    rotulo: 'CPF (opcional)',
                    child: TextFormField(
                      controller: _cpfController,
                      decoration: const InputDecoration(
                        hintText: '000.000.000-00',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CpfCnpjInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return cpfValido(v) ? null : 'CPF inválido';
                      },
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
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
