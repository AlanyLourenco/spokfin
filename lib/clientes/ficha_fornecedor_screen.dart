import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'cliente_form_screen.dart';

const _tiposChavePixRotulo = {
  'cpf_cnpj': 'CPF/CNPJ',
  'email': 'E-mail',
  'telefone': 'Telefone',
  'aleatoria': 'Chave Aleatória',
};

class FichaFornecedorScreen extends StatefulWidget {
  const FichaFornecedorScreen({
    super.key,
    required this.empresaId,
    required this.fornecedor,
  });

  final String empresaId;
  final Map<String, dynamic> fornecedor;

  @override
  State<FichaFornecedorScreen> createState() => _FichaFornecedorScreenState();
}

class _FichaFornecedorScreenState extends State<FichaFornecedorScreen> {
  late Map<String, dynamic> _fornecedor;

  String get _nome => _fornecedor['nome'] as String? ?? '';
  String? get _telefone => _fornecedor['telefone'] as String?;
  String? get _chavePix => _fornecedor['chave_pix'] as String?;
  String? get _tipoChavePix => _fornecedor['tipo_chave_pix'] as String?;

  @override
  void initState() {
    super.initState();
    _fornecedor = widget.fornecedor;
  }

  Future<void> _editar() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(
          empresaId: widget.empresaId,
          cliente: _fornecedor,
        ),
      ),
    );
    if (alterou == true) {
      final atualizado = await supabase
          .from('clientes')
          .select()
          .eq('id', _fornecedor['id'] as String)
          .single();
      setState(() => _fornecedor = atualizado);
    }
  }

  Future<void> _copiarPix() async {
    if (_chavePix == null || _chavePix!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _chavePix!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chave PIX copiada')),
    );
  }

  Future<void> _excluirOuArquivar() async {
    final fornecedorId = _fornecedor['id'] as String;
    final temTransacao = await supabase
        .from('transacoes')
        .select('id')
        .eq('cliente_id', fornecedorId)
        .limit(1);
    final temConta = await supabase
        .from('contas_pagar_receber')
        .select('id')
        .eq('cliente_id', fornecedorId)
        .limit(1);
    final temLancamentos = temTransacao.isNotEmpty || temConta.isNotEmpty;

    if (!mounted) return;
    if (temLancamentos) {
      final arquivar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fornecedor com lançamentos'),
          content: Text(
            '"$_nome" tem lançamentos vinculados, então não pode ser excluído — isso apagaria o histórico. Você pode arquivá-lo: ele some da lista de fornecedores, mas o histórico continua intacto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar fornecedor'),
            ),
          ],
        ),
      );
      if (arquivar != true) return;
      await supabase
          .from('clientes')
          .update({'ativo': false})
          .eq('id', fornecedorId);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final excluir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir fornecedor?'),
        content: Text(
          '"$_nome" não tem nenhum lançamento vinculado. Isso vai excluí-lo permanentemente.',
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
    if (excluir != true) return;
    await supabase.from('clientes').delete().eq('id', fornecedorId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final iniciais = iniciaisDoNome(_nome);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha do Fornecedor'),
        actions: [
          IconButton(
            onPressed: _excluirOuArquivar,
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Excluir fornecedor',
          ),
          TextButton.icon(
            onPressed: _editar,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceAlt,
                    child: Text(
                      iniciais,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_telefone != null && _telefone!.isNotEmpty)
                          Text(
                            _telefone!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RotuloCard('CHAVE PIX'),
                    const SizedBox(height: 6),
                    if (_chavePix == null || _chavePix!.isEmpty)
                      const Text(
                        'Nenhuma chave cadastrada',
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    else ...[
                      Text(
                        _chavePix!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tiposChavePixRotulo[_tipoChavePix] ?? '',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _copiarPix,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar PIX'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
