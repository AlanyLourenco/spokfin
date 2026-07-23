import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'cliente_form_screen.dart';
import 'ficha_cliente_screen.dart';

const _tamanhoPagina = 30;

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>>? _clientes;
  bool _temMais = false;
  bool _carregandoMais = false;
  String? _ultimoNome;
  String? _erro;

  List<Map<String, dynamic>>? _resultadoBusca;
  bool _buscando = false;
  Timer? _debounce;

  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPrimeiraPagina();
    _buscaController.addListener(_onBuscaMudou);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.removeListener(_onBuscaMudou);
    _buscaController.dispose();
    super.dispose();
  }

  void _onBuscaMudou() {
    _debounce?.cancel();
    final termo = _buscaController.text.trim();
    if (termo.isEmpty) {
      setState(() => _resultadoBusca = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _buscar(termo));
  }

  Future<void> _buscar(String termo) async {
    setState(() => _buscando = true);
    try {
      final rows = await supabase
          .from('clientes')
          .select()
          .eq('empresa_id', widget.empresaId)
          .eq('ativo', true)
          .ilike('nome', '%$termo%')
          .order('nome')
          .limit(50);
      final comAgregados = await _comAgregados(
        List<Map<String, dynamic>>.from(rows),
      );
      if (!mounted) return;
      setState(() => _resultadoBusca = comAgregados);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro na busca: $e')));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _recarregar() {
    _ultimoNome = null;
    _carregarPrimeiraPagina();
    if (_buscaController.text.trim().isNotEmpty) {
      _buscar(_buscaController.text.trim());
    }
  }

  Future<void> _carregarPrimeiraPagina() async {
    setState(() {
      _clientes = null;
      _erro = null;
    });
    try {
      final pagina = await _buscarPagina(cursor: null);
      if (!mounted) return;
      setState(() {
        _clientes = pagina.itens;
        _temMais = pagina.temMais;
        _ultimoNome = pagina.itens.isEmpty
            ? null
            : pagina.itens.last['nome'] as String;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    }
  }

  Future<void> _carregarMais() async {
    setState(() => _carregandoMais = true);
    try {
      final pagina = await _buscarPagina(cursor: _ultimoNome);
      if (!mounted) return;
      setState(() {
        _clientes = [...?_clientes, ...pagina.itens];
        _temMais = pagina.temMais;
        if (pagina.itens.isNotEmpty) {
          _ultimoNome = pagina.itens.last['nome'] as String;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar mais: $e')));
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  Future<_PaginaClientes> _buscarPagina({required String? cursor}) async {
    var query = supabase
        .from('clientes')
        .select()
        .eq('empresa_id', widget.empresaId)
        .eq('ativo', true);
    if (cursor != null) {
      query = query.gt('nome', cursor);
    }
    final rows = await query.order('nome').limit(_tamanhoPagina);
    final clientes = List<Map<String, dynamic>>.from(rows);
    final comAgregados = await _comAgregados(clientes);
    return _PaginaClientes(
      itens: comAgregados,
      temMais: clientes.length >= _tamanhoPagina,
    );
  }

  Future<List<Map<String, dynamic>>> _comAgregados(
    List<Map<String, dynamic>> clientes,
  ) async {
    if (clientes.isEmpty) return [];
    final clienteIds = clientes.map((c) => c['id'] as String).toList();

    final transacoes = await supabase
        .from('transacoes')
        .select('cliente_id, data_transacao')
        .eq('empresa_id', widget.empresaId)
        .inFilter('cliente_id', clienteIds);

    final contas = await supabase
        .from('contas_pagar_receber')
        .select('cliente_id, vencimento, valor, tipo, status')
        .eq('empresa_id', widget.empresaId)
        .inFilter('cliente_id', clienteIds);

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
      body: Builder(
        builder: (context) {
          if (_erro != null) {
            return Center(child: Text('Erro: $_erro'));
          }
          if (_clientes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final buscando = _buscaController.text.trim().isNotEmpty;
          final clientes = buscando ? _resultadoBusca : _clientes;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nome...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: buscando && _buscando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: clientes == null
                    ? const Center(child: CircularProgressIndicator())
                    : clientes.isEmpty
                    ? Center(
                        child: Text(
                          buscando
                              ? 'Nenhum cliente encontrado'
                              : 'Nenhum cliente cadastrado ainda',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount:
                            clientes.length +
                            (!buscando && _temMais ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == clientes.length) {
                            return Center(
                              child: _carregandoMais
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _carregarMais,
                                      child: const Text('Carregar mais'),
                                    ),
                            );
                          }
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
                                      formatarMoeda(debito),
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

class _PaginaClientes {
  _PaginaClientes({required this.itens, required this.temMais});

  final List<Map<String, dynamic>> itens;
  final bool temMais;
}

String _formatarData(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
