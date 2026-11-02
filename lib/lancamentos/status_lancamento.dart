import 'package:flutter/material.dart';

import '../theme.dart';

/// Tradução única de status de lançamento para o rótulo que a tela mostra.
///
/// Antes desta função a mesma regra estava copiada na Home, no Histórico, no
/// modal de Detalhes e no MRR — e "atrasado" nunca é gravado no banco (é
/// derivado do vencimento pela view `contas_pagar_receber_vw`), então quem lê
/// `status` cru precisa desta tradução para não mostrar o texto errado.
String rotuloStatus(String status) => switch (status) {
  'pago' => 'Pago',
  'atrasado' => 'Atrasado',
  _ => 'Pendente',
};

/// Cor do rótulo de status. Verde é dinheiro recebido/quitado, vermelho é
/// atraso; pendente é neutro porque ainda não é problema.
Color corStatus(String status) => switch (status) {
  'pago' => AppColors.accent,
  'atrasado' => AppColors.negative,
  _ => AppColors.textMuted,
};

/// Ícone de marca do status em lista (Histórico). Distingue só pago de
/// não-pago: atrasado e pendente compartilham a mesma marca vazia.
IconData iconeStatus(String status) =>
    status == 'pago' ? Icons.check_circle : Icons.radio_button_unchecked;

/// Cor do ícone de [iconeStatus] — binária como ele, e por isso diferente de
/// [corStatus], que distingue os três estados (ver DV6 no `design.md` da spec
/// `0010`).
Color corIconeStatus(String status) =>
    status == 'pago' ? AppColors.accent : AppColors.textMuted;
