import '../main.dart';
import '../shared/formatters.dart';
import 'lancamento_detalhado.dart';

/// Leitura de lançamentos do Supabase — a única do app.
///
/// Home, Histórico, Balanço e Ficha do Cliente mostram o mesmo conceito com
/// recortes diferentes (limite, período, cliente, incluir ou não pagos), e
/// antes da spec `0010` cada uma repetia a mesma consulta "transações +
/// contas + resolver nome do cliente + mesclar e ordenar". As diferenças
/// reais viraram os parâmetros abaixo; a consulta é uma só.
///
/// São funções de topo de arquivo, sem classe: não há estado a guardar e o
/// cliente `supabase` já é global (mesmo estilo de `formatters.dart`).

/// Uma página do Histórico: os itens já cortados no limite pedido, mais o
/// sinal de que ainda há o que carregar.
class PaginaLancamentos {
  PaginaLancamentos({required this.itens, required this.temMais});

  final List<LancamentoDetalhado> itens;
  final bool temMais;
}

/// Lê transações e/ou contas, resolve o nome do cliente numa consulta só,
/// mescla as duas fontes e ordena por data (mais recente primeiro).
///
/// [ate] é exclusivo (`<`), [de] é inclusivo (`>=`) — é o recorte de período
/// que o Balanço já usava. [limitePorFonte] limita **cada fonte**, não o
/// resultado: quem chama corta o total, se precisar (ver
/// [buscarPaginaLancamentos]).
Future<List<LancamentoDetalhado>> buscarLancamentos({
  String? empresaId,
  String? clienteId,
  DateTime? de,
  DateTime? ate,
  int? limitePorFonte,
  bool incluirTransacoes = true,
  bool incluirContas = true,
  bool incluirContasPagas = false,
  bool ignorarCancelados = false,
}) async {
  final bruto = await _carregarBruto(
    empresaId: empresaId,
    clienteId: clienteId,
    de: de,
    ate: ate,
    limitePorFonte: limitePorFonte,
    incluirTransacoes: incluirTransacoes,
    incluirContas: incluirContas,
    incluirContasPagas: incluirContasPagas,
  );
  return bruto.montar(ignorarCancelados: ignorarCancelados);
}

/// A leitura do Histórico: as `limite` transações e as `limite` contas mais
/// recentes, mescladas e cortadas em `limite`.
///
/// Como cada fonte já traz suas `limite` linhas mais recentes, o topo-`limite`
/// combinado nunca perde um item que deveria aparecer — só pode trazer itens
/// repetidos de sobra, que são cortados no final.
Future<PaginaLancamentos> buscarPaginaLancamentos({
  required String empresaId,
  required int limite,
  bool ignorarCancelados = false,
}) async {
  final bruto = await _carregarBruto(
    empresaId: empresaId,
    limitePorFonte: limite,
  );
  final itens = bruto.montar(ignorarCancelados: ignorarCancelados);
  return PaginaLancamentos(
    itens: itens.take(limite).toList(),
    temMais:
        bruto.transacoes.length >= limite || bruto.contas.length >= limite,
  );
}

/// Contas ainda pendentes que vencem nos próximos [dias], da mais próxima do
/// vencimento para a mais distante — a lista "Vencendo em breve" da Home.
Future<List<LancamentoDetalhado>> buscarVencendoEmBreve({
  required String empresaId,
  required int dias,
}) async {
  final hoje = DateTime.now();
  final limite = hoje.add(Duration(days: dias));

  final rows = List<Map<String, dynamic>>.from(
    await supabase
        .from('contas_pagar_receber_vw')
        .select()
        .eq('empresa_id', empresaId)
        .eq('status_efetivo', 'pendente')
        .gte('vencimento', formatarDataIso(hoje))
        .lte('vencimento', formatarDataIso(limite))
        .order('vencimento'),
  );

  final nomes = await _resolverNomesDeClientes([rows]);
  return <LancamentoDetalhado>[
    for (final r in rows)
      LancamentoDetalhado.deConta(r, clienteNome: nomes[r['cliente_id']]),
  ]..sort((a, b) => a.data.compareTo(b.data));
}

/// As linhas cruas das duas fontes mais o mapa de nomes de cliente, antes de
/// virarem modelo. Existe para que [buscarPaginaLancamentos] possa olhar a
/// contagem por fonte (o sinal de "tem mais") sem repetir a consulta.
class _Bruto {
  _Bruto({
    required this.transacoes,
    required this.contas,
    required this.nomes,
  });

  final List<Map<String, dynamic>> transacoes;
  final List<Map<String, dynamic>> contas;
  final Map<String, String> nomes;

  List<LancamentoDetalhado> montar({required bool ignorarCancelados}) {
    return <LancamentoDetalhado>[
      for (final t in transacoes)
        LancamentoDetalhado.deTransacao(t, clienteNome: nomes[t['cliente_id']]),
      for (final c in contas)
        if (!(ignorarCancelados &&
            (c['status_efetivo'] ?? c['status']) == 'cancelado'))
          LancamentoDetalhado.deConta(c, clienteNome: nomes[c['cliente_id']]),
    ]..sort((a, b) => b.data.compareTo(a.data));
  }
}

Future<_Bruto> _carregarBruto({
  String? empresaId,
  String? clienteId,
  DateTime? de,
  DateTime? ate,
  int? limitePorFonte,
  bool incluirTransacoes = true,
  bool incluirContas = true,
  bool incluirContasPagas = false,
}) async {
  final transacoes = incluirTransacoes
      ? await _buscarTransacoes(
          empresaId: empresaId,
          clienteId: clienteId,
          de: de,
          ate: ate,
          limite: limitePorFonte,
        )
      : <Map<String, dynamic>>[];

  final contas = incluirContas
      ? await _buscarContas(
          empresaId: empresaId,
          clienteId: clienteId,
          de: de,
          ate: ate,
          limite: limitePorFonte,
          incluirPagas: incluirContasPagas,
        )
      : <Map<String, dynamic>>[];

  return _Bruto(
    transacoes: transacoes,
    contas: contas,
    nomes: await _resolverNomesDeClientes([transacoes, contas]),
  );
}

Future<List<Map<String, dynamic>>> _buscarTransacoes({
  String? empresaId,
  String? clienteId,
  DateTime? de,
  DateTime? ate,
  int? limite,
}) async {
  var query = supabase.from('transacoes').select();
  if (empresaId != null) query = query.eq('empresa_id', empresaId);
  if (clienteId != null) query = query.eq('cliente_id', clienteId);
  if (de != null) query = query.gte('data_transacao', formatarDataIso(de));
  if (ate != null) query = query.lt('data_transacao', formatarDataIso(ate));

  final ordenada = query.order('data_transacao', ascending: false);
  return List<Map<String, dynamic>>.from(
    limite == null ? await ordenada : await ordenada.limit(limite),
  );
}

/// Lê sempre a view, nunca a tabela crua: a view é `contas_pagar_receber.*`
/// mais `status_efetivo`, então não se perde coluna nenhuma e o "atrasado"
/// derivado do vencimento vem de graça.
Future<List<Map<String, dynamic>>> _buscarContas({
  String? empresaId,
  String? clienteId,
  DateTime? de,
  DateTime? ate,
  int? limite,
  bool incluirPagas = false,
}) async {
  var query = supabase.from('contas_pagar_receber_vw').select();
  if (empresaId != null) query = query.eq('empresa_id', empresaId);
  if (clienteId != null) query = query.eq('cliente_id', clienteId);
  if (!incluirPagas) query = query.neq('status_efetivo', 'pago');
  if (de != null) query = query.gte('vencimento', formatarDataIso(de));
  if (ate != null) query = query.lt('vencimento', formatarDataIso(ate));

  final ordenada = query.order('vencimento', ascending: false);
  return List<Map<String, dynamic>>.from(
    limite == null ? await ordenada : await ordenada.limit(limite),
  );
}

/// Uma consulta só para todos os `cliente_id` das linhas carregadas.
Future<Map<String, String>> _resolverNomesDeClientes(
  List<List<Map<String, dynamic>>> fontes,
) async {
  final ids = <String>{
    for (final fonte in fontes)
      for (final row in fonte)
        if (row['cliente_id'] != null) row['cliente_id'] as String,
  }.toList();
  if (ids.isEmpty) return const {};

  final clientes = List<Map<String, dynamic>>.from(
    await supabase.from('clientes').select('id, nome').inFilter('id', ids),
  );
  return {for (final c in clientes) c['id'] as String: c['nome'] as String};
}
