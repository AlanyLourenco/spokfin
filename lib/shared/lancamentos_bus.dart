import 'package:flutter/foundation.dart';

/// Contador incrementado sempre que um lançamento é criado, editado,
/// excluído ou muda de status em qualquer lugar do app. Telas que ficam
/// vivas em segundo plano (dentro do IndexedStack do MainShell) escutam
/// esse valor para saber quando precisam recarregar seus próprios dados,
/// já que não são recriadas ao trocar de aba.
final ValueNotifier<int> lancamentosAtualizados = ValueNotifier<int>(0);

void notificarLancamentosAtualizados() {
  lancamentosAtualizados.value++;
}
