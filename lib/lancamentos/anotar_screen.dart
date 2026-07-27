import 'package:flutter/material.dart';

import '../shared/campo_rotulado.dart';
import 'ia_service.dart';
import 'revisar_lancamento_screen.dart';

class AnotarScreen extends StatefulWidget {
  const AnotarScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<AnotarScreen> createState() => _AnotarScreenState();
}

const _tamanhoMaximoTexto = 300;
const _tamanhoMinimoTexto = 3;

class _AnotarScreenState extends State<AnotarScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<LancamentoExtraido?> _extrairComRetry(String texto) async {
    for (var tentativa = 0; tentativa < 2; tentativa++) {
      try {
        return await extrairLancamento(texto);
      } on LimiteIaExcedido {
        rethrow;
      } catch (_) {
        if (tentativa == 1) return null;
      }
    }
    return null;
  }

  Future<void> _processar() async {
    final texto = _controller.text.trim();
    if (texto.length < _tamanhoMinimoTexto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite pelo menos alguns caracteres.')),
      );
      return;
    }

    setState(() => _loading = true);

    LancamentoExtraido? lancamento;
    try {
      lancamento = await _extrairComRetry(texto);
    } on LimiteIaExcedido catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.mensagem)));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    final entrada =
        lancamento ??
        LancamentoExtraido(
          tipo: 'entrada',
          valor: 0,
          descricao: '',
          categoria: '',
          status: 'pago',
          querNotaFiscal: false,
        );
    if (lancamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não consegui entender — preencha manualmente.'),
        ),
      );
    }

    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RevisarLancamentoScreen(
          empresaId: widget.empresaId,
          lancamento: entrada,
        ),
      ),
    );
    if (salvou == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotar rápido'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoRotulado(
                  rotulo: 'Digite o que aconteceu',
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: _tamanhoMaximoTexto,
                    decoration: const InputDecoration(
                      hintText: 'ex: recebi 300 do João',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _processar,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Processar com IA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
