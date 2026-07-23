import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../theme.dart';
import 'ficha_assinante_screen.dart';
import 'nova_assinatura_screen.dart';

class MrrScreen extends StatefulWidget {
  const MrrScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<MrrScreen> createState() => _MrrScreenState();
}

class _MrrScreenState extends State<MrrScreen> {
  late Future<_MrrDados> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  Future<_MrrDados> _carregar() async {
    final mrr = await supabase.rpc(
      'calcular_mrr',
      params: {'p_empresa_id': widget.empresaId},
    );

    final assinaturas = await supabase
        .from('assinaturas_com_status')
        .select()
        .eq('empresa_id', widget.empresaId)
        .order('created_at', ascending: false);

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

    return _MrrDados(mrr: (mrr as num).toDouble(), assinaturas: lista);
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
      body: FutureBuilder<_MrrDados>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final dados = snapshot.data!;
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
                            '${dados.assinaturas.length}',
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
                            'R\$ ${dados.mrr.toStringAsFixed(2)}',
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
              if (dados.assinaturas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Nenhuma assinatura cadastrada ainda',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                for (final a in dados.assinaturas)
                  _AssinaturaTile(assinatura: a, onTap: () => _abrirFicha(a)),
            ],
          );
        },
      ),
    );
  }
}

class _MrrDados {
  _MrrDados({required this.mrr, required this.assinaturas});

  final double mrr;
  final List<Map<String, dynamic>> assinaturas;
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
            'R\$ ${valor.toStringAsFixed(2)}/mês · todo dia $diaVencimento',
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
