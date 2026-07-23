import 'package:flutter/material.dart';

import '../main.dart';
import '../shared/app_card.dart';
import '../theme.dart';

const _nomesMesesCompletos = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class BalancoScreen extends StatefulWidget {
  const BalancoScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<BalancoScreen> createState() => _BalancoScreenState();
}

class _BalancoScreenState extends State<BalancoScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<_BalancoDados> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  void _mesAnterior() {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month - 1);
      _future = _carregar();
    });
  }

  void _mesSeguinte() {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + 1);
      _future = _carregar();
    });
  }

  Future<_BalancoDados> _carregar() async {
    final inicio = DateTime(_mes.year, _mes.month, 1);
    final fim = DateTime(_mes.year, _mes.month + 1, 1);

    final transacoes = await supabase
        .from('transacoes')
        .select('tipo, valor')
        .eq('empresa_id', widget.empresaId)
        .gte('data_transacao', inicio.toIso8601String().split('T').first)
        .lt('data_transacao', fim.toIso8601String().split('T').first);

    double receitas = 0;
    double despesas = 0;
    for (final t in transacoes) {
      final valor = (t['valor'] as num).toDouble();
      if (t['tipo'] == 'entrada') {
        receitas += valor;
      } else {
        despesas += valor;
      }
    }
    return _BalancoDados(receitas: receitas, despesas: despesas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balancete Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: supabase.auth.signOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FutureBuilder<_BalancoDados>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              final dados = snapshot.data!;
              final liquido = dados.receitas - dados.despesas;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _mesAnterior,
                      ),
                      Text(
                        '${_nomesMesesCompletos[_mes.month - 1]} ${_mes.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _mesSeguinte,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LUCRO LÍQUIDO',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${liquido.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: liquido >= 0
                                ? AppColors.accent
                                : AppColors.negative,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RECEITAS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${dados.receitas.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                                'DESPESAS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${dados.despesas.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.negative,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BalancoDados {
  _BalancoDados({required this.receitas, required this.despesas});

  final double receitas;
  final double despesas;
}
