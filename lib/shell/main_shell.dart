import 'package:flutter/material.dart';

import '../balanco/balanco_screen.dart';
import '../clientes/clientes_screen.dart';
import '../empresa/home_screen.dart';
import '../historico/historico_screen.dart';
import '../mrr/mrr_screen.dart';
import '../shared/quick_actions_speed_dial.dart';
import 'navegacao_flutuante.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.empresaId,
    required this.nomeExibicao,
  });

  final String empresaId;
  final String nomeExibicao;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final abas = [
      _Aba(
        icone: Icons.home_outlined,
        rotulo: 'Home',
        corpo: HomeTabContent(
          empresaId: widget.empresaId,
          nomeExibicao: widget.nomeExibicao,
          onVerHistorico: () => setState(() => _index = 3),
        ),
      ),
      _Aba(
        icone: Icons.bar_chart_outlined,
        rotulo: 'Balanço',
        corpo: BalancoScreen(empresaId: widget.empresaId),
      ),
      _Aba(
        icone: Icons.autorenew,
        rotulo: 'MRR',
        corpo: MrrScreen(empresaId: widget.empresaId),
      ),
      _Aba(
        icone: Icons.receipt_long_outlined,
        rotulo: 'Histórico',
        corpo: HistoricoScreen(empresaId: widget.empresaId),
      ),
      _Aba(
        icone: Icons.people_outline,
        rotulo: 'Clientes',
        corpo: ClientesScreen(empresaId: widget.empresaId),
      ),
    ];

    return Scaffold(
      // O conteúdo corre por baixo da pílula de navegação, que flutua.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: abas.map((a) => a.corpo).toList(),
      ),
      floatingActionButton: _index == 0
          ? null
          : QuickActionsSpeedDial(empresaId: widget.empresaId),
      bottomNavigationBar: NavegacaoFlutuante(
        itens: [
          for (final a in abas)
            ItemNavegacao(icone: a.icone, rotulo: a.rotulo),
        ],
        indiceSelecionado: _index,
        aoSelecionar: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _Aba {
  _Aba({required this.icone, required this.rotulo, required this.corpo});

  final IconData icone;
  final String rotulo;
  final Widget corpo;
}

