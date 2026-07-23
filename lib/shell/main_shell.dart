import 'package:flutter/material.dart';

import '../balanco/balanco_screen.dart';
import '../clientes/clientes_screen.dart';
import '../empresa/home_screen.dart';
import '../historico/historico_screen.dart';
import '../mrr/mrr_screen.dart';
import '../shared/quick_actions_speed_dial.dart';
import '../theme.dart';

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
      body: IndexedStack(
        index: _index,
        children: abas.map((a) => a.corpo).toList(),
      ),
      floatingActionButton: _index == 0
          ? null
          : QuickActionsSpeedDial(empresaId: widget.empresaId),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.accent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.background
                  : AppColors.textMuted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final a in abas)
              NavigationDestination(icon: Icon(a.icone), label: a.rotulo),
          ],
        ),
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

