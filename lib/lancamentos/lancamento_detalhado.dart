/// Representa um lançamento (transação já paga ou conta a pagar/receber
/// pendente) de forma unificada, para telas que mostram os dois tipos juntos.
class LancamentoDetalhado {
  LancamentoDetalhado({
    required this.id,
    required this.origem,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.status,
    this.clienteId,
    this.clienteNome,
    this.notaFiscalStatus = 'nao_aplicavel',
  });

  /// 'transacao' (já paga) ou 'conta' (contas_pagar_receber, pendente/atrasada).
  final String id;
  final String origem;
  final String descricao;
  final String categoria;
  final double valor;

  /// 'entrada' ou 'saida'.
  final String tipo;
  final DateTime data;

  /// 'pago', 'pendente' ou 'atrasado'.
  final String status;
  final String? clienteId;
  final String? clienteNome;

  /// 'nao_aplicavel', 'pendente' ou 'emitida'.
  final String notaFiscalStatus;

  LancamentoDetalhado copiarCom({
    String? descricao,
    String? categoria,
    double? valor,
    String? notaFiscalStatus,
  }) {
    return LancamentoDetalhado(
      id: id,
      origem: origem,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      tipo: tipo,
      data: data,
      status: status,
      clienteId: clienteId,
      clienteNome: clienteNome,
      notaFiscalStatus: notaFiscalStatus ?? this.notaFiscalStatus,
    );
  }
}
