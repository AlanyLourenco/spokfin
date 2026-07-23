import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../theme.dart';
import 'cliente_form_screen.dart';
import 'ficha_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final clientes = await supabase
        .from('clientes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .eq('ativo', true)
        .order('nome');

    final transacoes = await supabase
        .from('transacoes')
        .select('cliente_id, data_transacao')
        .eq('empresa_id', widget.empresaId)
        .not('cliente_id', 'is', null);

    final contas = await supabase
        .from('contas_pagar_receber')
        .select('cliente_id, vencimento, valor, tipo, status')
        .eq('empresa_id', widget.empresaId)
        .not('cliente_id', 'is', null);

    final ultimoPorCliente = <String, DateTime>{};
    void registrarData(String? clienteId, String dataIso) {
      if (clienteId == null) return;
      final data = DateTime.parse(dataIso);
      final atual = ultimoPorCliente[clienteId];
      if (atual == null || data.isAfter(atual)) {
        ultimoPorCliente[clienteId] = data;
      }
    }

    final debitoPorCliente = <String, double>{};

    for (final t in transacoes) {
      registrarData(t['cliente_id'] as String?, t['data_transacao'] as String);
    }
    for (final c in contas) {
      registrarData(c['cliente_id'] as String?, c['vencimento'] as String);
      if (c['tipo'] == 'receber' && c['status'] == 'pendente') {
        final clienteId = c['cliente_id'] as String;
        debitoPorCliente[clienteId] =
            (debitoPorCliente[clienteId] ?? 0) + (c['valor'] as num).toDouble();
      }
    }

    return [
      for (final c in clientes)
        {
          ...c,
          'ultimo': ultimoPorCliente[c['id']],
          'debito': debitoPorCliente[c['id']] ?? 0.0,
        },
    ];
  }

  Future<void> _novoCliente() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(empresaId: widget.empresaId),
      ),
    );
    if (salvou == true) _recarregar();
  }

  Future<void> _abrirFicha(Map<String, dynamic> cliente) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FichaClienteScreen(empresaId: widget.empresaId, cliente: cliente),
      ),
    );
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes e Devedores'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _novoCliente,
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('Novo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: supabase.auth.signOut,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum cliente cadastrado ainda',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          final busca = _buscaController.text.trim().toLowerCase();
          final clientes = busca.isEmpty
              ? todos
              : todos
                    .where(
                      (c) => (c['nome'] as String? ?? '')
                          .toLowerCase()
                          .contains(busca),
                    )
                    .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _buscaController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente por nome...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: clientes.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum cliente encontrado',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: clientes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = clientes[i];
                          final nome = c['nome'] as String? ?? '';
                          final ultimo = c['ultimo'] as DateTime?;
                          final debito = c['debito'] as double;
                          final iniciais = nome.isEmpty
                              ? '?'
                              : nome
                                    .trim()
                                    .split(RegExp(r'\s+'))
                                    .take(2)
                                    .map((p) => p[0])
                                    .join()
                                    .toUpperCase();
                          return AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceAlt,
                                child: Text(
                                  iniciais,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              title: Text(nome),
                              subtitle: Text(
                                ultimo == null
                                    ? 'Sem lançamentos'
                                    : 'Último: ${_formatarData(ultimo)}',
                              ),
                              trailing: debito > 0
                                  ? Text(
                                      'R\$ ${debito.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.negative,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              onTap: () => _abrirFicha(c),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatarData(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
