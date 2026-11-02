import 'package:flutter/material.dart';

import '../shared/motion.dart';
import '../theme.dart';

/// Item da [NavegacaoFlutuante].
class ItemNavegacao {
  const ItemNavegacao({required this.icone, required this.rotulo});

  final IconData icone;
  final String rotulo;
}

/// A navegação inferior do app: uma pílula arredondada que flutua sobre o
/// conteúdo, com a aba ativa preenchida (spec `0012`).
///
/// É um widget próprio, e não um `NavigationBar` do Material 3 estilizado,
/// porque o componente do Material não faz pílula flutuante com indicador
/// retangular preenchido sem briga com `indicatorShape`/`height`/
/// `labelBehavior` — um `Row` de 5 itens é menos código do que dobrá-lo.
class NavegacaoFlutuante extends StatelessWidget {
  const NavegacaoFlutuante({
    super.key,
    required this.itens,
    required this.indiceSelecionado,
    required this.aoSelecionar,
  });

  final List<ItemNavegacao> itens;
  final int indiceSelecionado;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              for (var i = 0; i < itens.length; i++)
                Expanded(
                  child: _ItemNav(
                    item: itens[i],
                    selecionado: i == indiceSelecionado,
                    aoTocar: () => aoSelecionar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({
    required this.item,
    required this.selecionado,
    required this.aoTocar,
  });

  final ItemNavegacao item;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.textPrimary : AppColors.textMuted;

    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: AppMotion.rapido,
        curve: AppMotion.entrada,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icone, size: 20, color: cor),
            const SizedBox(height: 2),
            Text(
              item.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: cor,
                fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
