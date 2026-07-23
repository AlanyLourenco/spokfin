import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'ficha_assinante_screen.dart';
import 'nova_assinatura_screen.dart';

const _tamanhoPagina = 30;

class MrrScreen extends StatefulWidget {
  const MrrScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<MrrScreen> createState() => _MrrScreenState();
}

class _MrrScreenState extends State<MrrScreen> {
  double? _mrr;
  int? _totalAtivos;
  List<Map<String, dynamic>>? _assinaturas;
  bool _temMais = false;
  bool _carregandoMais = false;
  String? _ultimoCreatedAt;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _recarregar() {
    _ultimoCreatedAt = null;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _assinaturas = null;
      _erro = null;
    });
    try {
      final mrr = await supabase.rpc(
        'calcular_mrr',
        params: {'p_empresa_id': widget.empresaId},
      );

      final ativos = await supabase
          .from('assinaturas')
          .select('id')
          .eq('empresa_id', widget.empresaId)
          .eq('status', 'ativa');

      final pagina = await _buscarPagina(cursor: null);
      if (!mounted) return;
      setState(() {
        _mrr = (mrr as num).toDouble();
        _totalAtivos = ativos.length;
        _assinaturas = pagina.itens;
        _temMais = pagina.temMais;
        _ultimoCreatedAt = pagina.itens.isEmpty
            ? null
            : pagina.itens.last['created_at'] as String;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    }
  }

  Future<void> _carregarMais() async {
    setState(() => _carregandoMais = true);
    try {
      final pagina = await _buscarPagina(cursor: _ultimoCreatedAt);
      if (!mounted) return;
      setState(() {
        _assinaturas = [...?_assinaturas, ...pagina.itens];
        _temMais = pagina.temMais;
        if (pagina.itens.isNotEmpty) {
          _ultimoCreatedAt = pagina.itens.last['created_at'] as String;
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

  Future<_PaginaAssinaturas> _buscarPagina({required String? cursor}) async {
    var query = supabase
        .from('assinaturas_com_status')
        .select()
        .eq('empresa_id', widget.empresaId);
    if (cursor != null) {
      query = query.lt('created_at', cursor);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .limit(_tamanhoPagina);
    final assinaturas = List<Map<String, dynamic>>.from(rows);

    final clienteIds = assinaturas
        .map((a) => a['cliente_id'] as String)
        .toSet()
        .toList();
    final clientes = clienteIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('clientes')
                .select('id, nome')
                .inFilter('id', clienteIds),
          );
    final nomesPorId = {
      for (final c in clientes) c['id'] as String: c['nome'] as String,
    };

    final lista = [
      for (final a in assinaturas)
        {...a, 'cliente_nome': nomesPorId[a['cliente_id']] ?? '—'},
    ];

    return _PaginaAssinaturas(
      itens: lista,
      temMais: assinaturas.length >= _tamanhoPagina,
    );
  }

  Future<void> _novaAssinatura() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NovaAssinaturaScreen(empresaId: widget.empresaId),
      ),
    );
    if (salvou == true) _recarregar();
  }

  Future<void> _abrirFicha(Map<String, dynamic> assinatura) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FichaAssinanteScreen(assinatura: assinatura),
      ),
    );
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinantes Mensais'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _novaAssinatura,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova'),
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
          if (_assinaturas == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final assinaturas = _assinaturas!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATIVOS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_totalAtivos ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MRR',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatarMoeda(_mrr ?? 0),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (assinaturas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Nenhuma assinatura cadastrada ainda',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else ...[
                for (final a in assinaturas)
                  _AssinaturaTile(assinatura: a, onTap: () => _abrirFicha(a)),
                if (_temMais)
                  Center(
                    child: _carregandoMais
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            onPressed: _carregarMais,
                            child: const Text('Carregar mais'),
                          ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PaginaAssinaturas {
  _PaginaAssinaturas({required this.itens, required this.temMais});

  final List<Map<String, dynamic>> itens;
  final bool temMais;
}

class _AssinaturaTile extends StatelessWidget {
  const _AssinaturaTile({required this.assinatura, required this.onTap});

  final Map<String, dynamic> assinatura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nome = assinatura['cliente_nome'] as String;
    final valor = (assinatura['valor_mensalidade'] as num).toDouble();
    final diaVencimento = assinatura['dia_vencimento'] as int;
    final status = assinatura['status_mes_atual'] as String;
    final pago = status == 'pago';
    final rotuloStatus = switch (status) {
      'pago' => 'Pago',
      'atrasado' => 'Atrasado',
      _ => 'Pendente',
    };
    final corStatus = pago
        ? AppColors.accent
        : (status == 'atrasado' ? AppColors.negative : AppColors.textMuted);

    final iniciais = nome.isEmpty
        ? '?'
        : nome
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceAlt,
            child: Text(
              iniciais,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
          title: Text(nome),
          subtitle: Text(
            '${formatarMoeda(valor)}/mês · todo dia $diaVencimento',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corStatus.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              rotuloStatus,
              style: TextStyle(
                color: corStatus,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
