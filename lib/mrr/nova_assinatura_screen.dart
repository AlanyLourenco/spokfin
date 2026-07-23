import 'package:flutter/material.dart';

import '../clientes/cliente_form_screen.dart';
import '../main.dart';
import '../shared/app_card.dart';
import '../theme.dart';

class NovaAssinaturaScreen extends StatefulWidget {
  const NovaAssinaturaScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<NovaAssinaturaScreen> createState() => _NovaAssinaturaScreenState();
}

class _NovaAssinaturaScreenState extends State<NovaAssinaturaScreen> {
  late Future<List<Map<String, dynamic>>> _clientesFuture;
  String? _clienteId;
  double _valor = 0;
  int _diaVencimento = 5;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientesFuture = _carregarClientes();
  }

  Future<List<Map<String, dynamic>>> _carregarClientes() async {
    final rows = await supabase
        .from('clientes')
        .select('id, nome')
        .eq('empresa_id', widget.empresaId)
        .order('nome');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _cadastrarCliente() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(empresaId: widget.empresaId),
      ),
    );
    if (salvou == true) {
      setState(() {
        _clientesFuture = _carregarClientes();
      });
    }
  }

  Future<void> _salvar() async {
    if (_clienteId == null) {
      setState(() => _error = 'Selecione um cliente');
      return;
    }
    if (_valor <= 0) {
      setState(() => _error = 'Informe o valor da mensalidade');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.from('assinaturas').insert({
        'empresa_id': widget.empresaId,
        'cliente_id': _clienteId,
        'valor_mensalidade': _valor,
        'dia_vencimento': _diaVencimento,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Assinatura')),
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
                          if (clientes.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Você ainda não tem clientes cadastrados.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: _cadastrarCliente,
                                  icon: const Icon(
                                    Icons.person_add_alt,
                                    size: 18,
                                  ),
                                  label: const Text('Cadastrar Cliente'),
                                ),
                              ],
                            );
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _clienteId,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            dropdownColor: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            hint: const Text('Selecione um cliente'),
                            items: [
                              for (final c in clientes)
                                DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(
                                    c['nome'] as String,
                                    style: TextStyle(
                                      color: _clienteId == c['id']
                                          ? AppColors.accent
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
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VALOR DA MENSALIDADE',
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
                        'DIA DO VENCIMENTO',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Todo dia $_diaVencimento',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.accent,
                          thumbColor: AppColors.accent,
                          inactiveTrackColor: AppColors.surfaceAlt,
                          overlayColor: AppColors.accent.withValues(alpha: 0.2),
                          valueIndicatorColor: AppColors.accent,
                        ),
                        child: Slider(
                          value: _diaVencimento.toDouble(),
                          min: 1,
                          max: 31,
                          divisions: 30,
                          label: '$_diaVencimento',
                          onChanged: (v) =>
                              setState(() => _diaVencimento = v.round()),
                        ),
                      ),
                    ],
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
                  onPressed: _loading ? null : _salvar,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar Assinatura'),
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
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      side: BorderSide.none,
    );
  }
}
