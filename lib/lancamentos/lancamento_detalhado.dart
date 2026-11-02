import 'status_lancamento.dart';

/// Representa um lançamento (transação já paga ou conta a pagar/receber
/// pendente) de forma unificada, para telas que mostram os dois tipos juntos.
///
/// É o **único** modelo de linha de lançamento do app: Home, Histórico,
/// Balanço e Ficha do Cliente consomem este tipo, carregado por
/// `lancamentos_repository.dart`. Não crie um modelo próprio de lançamento
/// numa tela nova — foi exatamente o que a spec `0010` desfez.
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

  /// Constrói a partir de uma linha da tabela `transacoes` — que, por
  /// definição, já é dinheiro que entrou ou saiu, logo `status: 'pago'`.
  factory LancamentoDetalhado.deTransacao(
    Map<String, dynamic> row, {
    String? clienteNome,
  }) {
    return LancamentoDetalhado(
      id: row['id'] as String,
      origem: 'transacao',
      descricao: row['descricao'] as String? ?? '',
      categoria: row['categoria'] as String? ?? '',
      valor: (row['valor'] as num).toDouble(),
      tipo: row['tipo'] as String,
      data: DateTime.parse(row['data_transacao'] as String),
      status: 'pago',
      clienteId: row['cliente_id'] as String?,
      clienteNome: clienteNome,
      notaFiscalStatus: row['nota_fiscal_status'] as String? ?? 'nao_aplicavel',
    );
  }

  /// Constrói a partir de uma linha de `contas_pagar_receber_vw`. Cai para a
  /// coluna `status` quando a linha vem da tabela crua (sem `status_efetivo`),
  /// e traduz `receber`/`pagar` para o `entrada`/`saida` que o resto do app usa.
  factory LancamentoDetalhado.deConta(
    Map<String, dynamic> row, {
    String? clienteNome,
  }) {
    return LancamentoDetalhado(
      id: row['id'] as String,
      origem: 'conta',
      descricao: row['descricao'] as String? ?? '',
      categoria: row['categoria'] as String? ?? '',
      valor: (row['valor'] as num).toDouble(),
      tipo: row['tipo'] == 'receber' ? 'entrada' : 'saida',
      data: DateTime.parse(row['vencimento'] as String),
      status: (row['status_efetivo'] ?? row['status']) as String,
      clienteId: row['cliente_id'] as String?,
      clienteNome: clienteNome,
      notaFiscalStatus: row['nota_fiscal_status'] as String? ?? 'nao_aplicavel',
    );
  }

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

  bool get pago => status == 'pago';

  bool get entrada => tipo == 'entrada';

  /// Derivado de [status], nunca guardado — assim é impossível o rótulo
  /// discordar do status depois de um [copiarCom].
  String get statusLabel => rotuloStatus(status);

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
