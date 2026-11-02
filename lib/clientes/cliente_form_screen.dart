import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../shared/campo_rotulado.dart';
import '../shared/mascaras.dart';
import '../shared/tilt_depth.dart';
import '../theme.dart';

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
  final _formKey = GlobalKey<FormState>();
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

  List<TextInputFormatter> _formatadoresChavePix() {
    switch (_tipoChavePix) {
      case 'cpf_cnpj':
        return [CpfCnpjInputFormatter()];
      case 'telefone':
        return [TelefoneInputFormatter()];
      default:
        return [];
    }
  }

  String? _validarChavePix(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null; // chave PIX é opcional

    if (_tipoChavePix == null) {
      return 'Selecione o tipo da chave';
    }
    switch (_tipoChavePix) {
      case 'cpf_cnpj':
        return cpfCnpjValido(texto) ? null : 'CPF/CNPJ inválido';
      case 'telefone':
        return telefoneValido(texto) ? null : 'Telefone inválido';
      case 'email':
        return emailValido(texto) ? null : 'E-mail inválido';
      default:
        return null;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
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
        if (_ehFornecedor)
          'tipo_chave_pix': chavePix.isEmpty ? null : _tipoChavePix,
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

  InputDecoration _decoracao(String hint) {
    return InputDecoration(hintText: hint);
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CampoRotulado(
                    rotulo: 'Nome / Empresa',
                    child: TextFormField(
                      controller: _nomeController,
                      decoration: _decoracao('Ex: João Mendes'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CampoRotulado(
                    rotulo: 'Número',
                    child: TextFormField(
                      controller: _telefoneController,
                      decoration: _decoracao('(00) 00000-0000'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [TelefoneInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return telefoneValido(v) ? null : 'Telefone inválido';
                      },
                    ),
                  ),
                  if (_ehFornecedor) ...[
                    const SizedBox(height: 16),
                    CampoRotulado(
                      rotulo: 'Chave PIX do Fornecedor (opcional)',
                      child: TextFormField(
                        controller: _chavePixController,
                        decoration: _decoracao('Digite a chave PIX'),
                        inputFormatters: _formatadoresChavePix(),
                        validator: _validarChavePix,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CampoRotulado(
                      rotulo: 'Tipo da Chave',
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoChavePix,
                        decoration: _decoracao('Selecione o tipo'),
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          for (final entrada in _tiposChavePix.entries)
                            DropdownMenuItem(
                              value: entrada.key,
                              child: Text(
                                entrada.value,
                                style: TextStyle(
                                  color: _tipoChavePix == entrada.key
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: _tipoChavePix == entrada.key
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _tipoChavePix = v),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TiltDepth(
                    maxAngle: 0.04,
                    child: FilledButton(
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
