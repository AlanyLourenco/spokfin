# Design — Organização do código: modelo e componentes de lançamento unificados

## Modelagem de dados

Nenhuma. Esta spec não cria migration, não altera tabela, view ou RPC. `contas_pagar_receber_vw` (migration `0002`) continua sendo `c.* + status_efetivo`, e é justamente por ser um superconjunto da tabela `contas_pagar_receber` que o repositório pode ler sempre a view sem perder coluna (ver §Decisões, D3).

## Backend

Nenhum. Nada de Edge Function, nada de RPC nova.

## Arquitetura

Três peças novas, todas em `lib/lancamentos/` (decisão do usuário: o domínio é "lançamento", não a tela — Home/Balanço/Histórico/Ficha são consumidores, do mesmo jeito que já consomem `lib/shared/lancamentos_bus.dart`).

### 1. `lib/lancamentos/lancamento_detalhado.dart` (existente, ampliado)

`LancamentoDetalhado` já tem exatamente os 13 campos que `_LancamentoResumo` e `_Item` reimplementam, com uma diferença: as cópias guardam `statusLabel` como **campo**, calculado na hora da carga. Aqui ele vira **getter derivado**, para não existir estado que possa contradizer `status`.

Ganha:

```dart
/// Constrói a partir de uma linha de `transacoes` (sempre paga).
factory LancamentoDetalhado.deTransacao(
  Map<String, dynamic> row, {
  String? clienteNome,
});

/// Constrói a partir de uma linha de `contas_pagar_receber_vw`
/// (ou da tabela crua — cai para `status` quando não há `status_efetivo`).
factory LancamentoDetalhado.deConta(
  Map<String, dynamic> row, {
  String? clienteNome,
});

bool get pago;      // status == 'pago'
bool get entrada;   // tipo == 'entrada'
String get statusLabel;  // delega para rotuloStatus(status)
```

As factories concentram as conversões que hoje estão copiadas em 4 telas: `data_transacao`/`vencimento` → `DateTime`, `'receber'`/`'pagar'` → `'entrada'`/`'saida'`, `descricao`/`categoria` nulos → `''`, `valor` `num` → `double`.

### 2. `lib/lancamentos/status_lancamento.dart` (novo)

Fonte única da tradução de status, hoje repetida em `home_screen.dart:168`, `historico_screen.dart:208`, `detalhes_lancamento_screen.dart:478` e `mrr_screen.dart:330`:

```dart
String rotuloStatus(String status);   // 'pago'→'Pago', 'atrasado'→'Atrasado', resto→'Pendente'
Color  corStatus(String status);      // pago→accent, atrasado→negative, pendente→textMuted
IconData iconeStatus(String status);  // pago→check_circle, resto→radio_button_unchecked
```

`rotuloStatus` é lógica pura e vai para `test/`. As 4 telas passam a consumir o rótulo daqui — **inclusive `mrr_screen.dart`**, que não usa `LancamentoDetalhado` (assinatura não é lançamento) mas repete a mesma tradução.

`corStatus`/`iconeStatus` são consumidos por quem hoje já usa exatamente esses valores (Histórico, MRR). `detalhes_lancamento_screen.dart` **mantém sua cor local** por ora — ela diverge (ver §Divergências, DV4) e corrigir seria mudança visível, o que esta spec proíbe.

### 3. `lib/lancamentos/lancamentos_repository.dart` (novo)

Substitui as ~60 linhas quase idênticas de `home_screen.dart:109-198` e `historico_screen.dart:144-215`, mais as cargas de Balanço e Ficha do Cliente. Funções de topo de arquivo (sem classe — não há estado a guardar; segue o estilo de `formatters.dart`/`lancamentos_bus.dart`):

```dart
/// Lê transações e/ou contas, resolve o nome do cliente numa consulta só,
/// mescla e ordena por data (mais recente primeiro).
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
});

/// Página do Histórico: mesma leitura + o sinal de "tem mais".
Future<PaginaLancamentos> buscarPaginaLancamentos({
  required String empresaId,
  required int limite,
  bool ignorarCancelados = false,
});

/// Contas pendentes vencendo nos próximos [dias], em ordem crescente
/// de vencimento (a lista "Vencendo em breve" da Home).
Future<List<LancamentoDetalhado>> buscarVencendoEmBreve({
  required String empresaId,
  required int dias,
});

class PaginaLancamentos {
  final List<LancamentoDetalhado> itens;
  final bool temMais;
}
```

`limitePorFonte` é por fonte, não do resultado — é a estratégia que o Histórico já usa e documenta em comentário (cada fonte traz suas N mais recentes, então o topo-N combinado nunca perde item; o corte final fica com quem chama). Esse comentário migra junto para o repositório.

A resolução de nome de cliente (coletar `cliente_id` não nulos → um `in` em `clientes` → `Map<id, nome>`) vira um helper privado do arquivo, hoje copiado em 3 telas.

Como cada tela chama:

| Tela | Chamada |
|---|---|
| Home — recentes | `buscarLancamentos(empresaId:, limitePorFonte: 5)` e depois `.take(5)` (idêntico ao de hoje) |
| Home — vencendo em breve | `buscarVencendoEmBreve(empresaId:, dias: _diasAlertaVencimento)` |
| Histórico | `buscarPaginaLancamentos(empresaId:, limite:, ignorarCancelados: true)` |
| Balanço | `buscarLancamentos(empresaId:, de:, ate:, incluirContas: false)` |
| Ficha do Cliente | `buscarLancamentos(clienteId:, incluirContasPagas: true)` |

O saldo, o total a pagar/receber, os agregados do Balanço (receitas, despesas, por dia, por categoria) e o débito/total pago da Ficha **não** entram no repositório: continuam onde estão, calculados na tela. O Balanço deixa de iterar linhas cruas do Supabase e passa a iterar a `List<LancamentoDetalhado>` que o repositório devolve — o laço de agregação é o mesmo, só muda a fonte.

### 4. `lib/lancamentos/lancamento_tile.dart` (novo — Etapa 2)

Um `LancamentoTile` só, no lugar de `_LancamentoTile` (Home), `_ItemTile` (Histórico) e `_LancamentoMesTile` (Balanço):

```dart
LancamentoTile({
  required LancamentoDetalhado lancamento,
  required String subtitulo,        // quem chama decide o que entra
  required VoidCallback onTap,
  bool emDestaque = false,          // Home: descrição 15, valor 16, padding 16
  bool mostrarIconeStatus = false,  // Histórico
  bool comBordaInferior = false,    // Histórico, Balanço
  bool mostrarNotaFiscal = true,    // Balanço passa false (ver DV3)
  bool pilulaComIcone = false,      // Home (ver DV2)
})
```

O subtítulo fica com quem chama porque as três telas compõem campos diferentes por motivo legítimo, não por descuido: Home mostra `categoria · status` (a data é irrelevante numa lista de "recentes"), Histórico mostra `data · categoria` (o status já está no ícone) e Balanço mostra `data · Pago · categoria` (só carrega transações, todas pagas). Os demais parâmetros existem para preservar diferenças que **são** descuido — cada um está marcado no código com o item de §Divergências que o justifica, para que a spec de correção saiba o que apagar.

Na implementação, os três parâmetros de tamanho previstos (`valorEmDestaque`, o `fontSize` da descrição e `paddingVertical`) sempre se moviam juntos — só a Home usa os três —, então viraram um `emDestaque` só. E o subtítulo passou a ser `Flexible` + elipse nas três telas: a Home usava um `Text` solto, que estouraria o layout num subtítulo longo em vez de cortar. Não muda nada com os dados reais (o subtítulo da Home é `categoria · status`), e remove um estouro latente.

A lista da Ficha do Cliente **não** usa este tile: é uma linha compacta genuinamente diferente (bolinha de status em vez de ícone, `formatarMoeda` em vez de `formatarValorCifrao`, sem categoria e sem nota fiscal). Ela migra para o modelo unificado na Etapa 1 e mantém seu próprio widget.

### 5. `PilulaNotaFiscal` (novo — Etapa 2)

A pílula "NFC-e agendada" (contêiner + borda `primary` + raio 999 + texto 10px w600), hoje em `home_screen.dart:707` e `historico_screen.dart:745`, vira um widget no mesmo arquivo do tile (`lancamento_tile.dart`) — é usada só por ele, e um arquivo separado com um widget de 20 linhas não se paga. Parâmetro `comIcone` enquanto DV2 não for resolvida.

## Telas / UI

Nenhuma mudança visível. Nenhum texto, cor, espaçamento, filtro, paginação ou ordenação muda. As 4 telas continuam com o mesmo layout — só param de carregar dado e desenhar linha cada uma do seu jeito.

## Etapas de execução

Fatiado em duas etapas (decisão do usuário), cada uma fechando com `flutter analyze` limpo e `flutter test` passando:

- **Etapa 1 — modelo + repositório.** É a que elimina o risco real: `_LancamentoResumo`, `_Item`, `_LancamentoMes` e `_ItemHistorico` deixam de existir; a carga vira uma função só. Os tiles continuam como estão, apenas trocando o tipo do parâmetro para `LancamentoDetalhado`.
- **Etapa 2 — componentes visuais.** `LancamentoTile` + `PilulaNotaFiscal` substituem os três tiles. Só mexe em `build`, sem tocar em carga de dados.

## Divergências encontradas (reportadas, não corrigidas aqui)

Levantadas ao ler as 4 telas. Nenhuma é corrigida nesta spec — o requisito é comportamento idêntico. Ficam registradas para virar uma spec própria, se o usuário quiser:

- **DV1 — a Home mostra contas canceladas, o Histórico não.** `historico_screen.dart:200` filtra `status_efetivo != 'cancelado'`; a carga da Home não filtra. Uma conta cancelada aparece nos "Lançamentos Recentes" e some no Histórico. Preservado pelo parâmetro `ignorarCancelados`. **É a divergência com maior chance de ser bug de verdade.**
- **DV2 — a pílula de NFC-e tem ícone na Home e não tem no Histórico.** Mesmo texto, mesma borda, mesma cor; `home_screen.dart:700` tem um `Icons.receipt_long` de 10px que `historico_screen.dart:744` não tem. Preservado por `pilulaComIcone`.
- **DV3 — o Balanço não mostra a pílula de NFC-e.** Carrega `nota_fiscal_status` no modelo e nunca desenha. Preservado por `mostrarNotaFiscal: false`.
- **DV4 — a cor de "Pendente" diverge, e uma delas está fora da paleta.** `detalhes_lancamento_screen.dart:482` usa `Color(0xFFF5A623)` (laranja escrito à mão, token que não existe em `AppColors`, o que contraria a convenção da spec `0009`); `mrr_screen.dart:337` usa `AppColors.textMuted` para o mesmo estado. Resolver exige decidir se a paleta ganha um token de alerta — decisão de identidade visual, dona da spec `0009`/`DESIGN.md`, não desta.
- **DV6 — o ícone de status do Histórico não distingue atrasado de pendente.** `corIconeStatus` é binária (pago → verde, resto → `textMuted`), enquanto `corStatus`, do rótulo de texto, distingue os três estados (atrasado → vermelho). Descoberto ao extrair: unificar as duas pintaria de vermelho ícones que hoje são cinza. Preservado como duas funções com nomes honestos em `status_lancamento.dart`.
- **DV5 — a Ficha do Cliente nunca mostra "Atrasado".** Lê a tabela crua `contas_pagar_receber` e usa `status`, então uma conta vencida aparece como "Pendente" ali e como "Atrasado" na Home/Histórico. Preservado: `buscarLancamentos` lê a view, mas a Ficha continua exibindo pelo booleano `pago`, o que reproduz o texto atual. Corrigir é trocar duas linhas — mas muda o que o usuário vê.

## Decisões técnicas e alternativas consideradas

- **D1 — `statusLabel` vira getter, não campo.** As cópias atuais guardam o rótulo junto com o status, o que permite os dois discordarem depois de um `copiarCom`. Como getter, é impossível.
- **D2 — funções de topo de arquivo em vez de uma classe `LancamentosRepository`.** Não há estado, dependência a injetar nem teste que se beneficie de mock (o cliente `supabase` é global desde `main.dart`, e o projeto não tem pacote de mock por decisão explícita). Uma classe só com métodos estáticos seria cerimônia sem retorno, e o projeto já resolve isso assim em `formatters.dart` e `mascaras.dart`.
- **D3 — o repositório lê sempre `contas_pagar_receber_vw`, nunca a tabela crua.** A view é `c.* + status_efetivo`: ler a view no lugar da tabela não perde coluna nenhuma e ainda dá `atrasado` de graça. A Ficha do Cliente, que hoje lê a tabela, passa a receber linhas da view — e continua exibindo pelo booleano `pago` (DV5), então o que o usuário vê não muda.
- **D4 — não incluir os agregados no repositório.** Saldo, débito, receitas/despesas e a contagem por mês são regras de cada tela, com filtros diferentes; puxá-las para cá criaria um objeto de resposta inchado que cada tela usaria pela metade. O requisito é unificar a **leitura de lançamento**, não a tela.
- **D5 — o subtítulo do tile é uma `String` recebida pronta.** Considerado um `enum FormatoSubtitulo` com as três combinações; rejeitado porque acrescenta vocabulário novo para exprimir três `join(' · ')` que a tela já sabe montar, e a próxima tela precisaria de mais um valor no enum.
- **D6 — a Ficha do Cliente mantém seu tile.** Espremer uma linha compacta com bolinha e `formatarMoeda` nos parâmetros do `LancamentoTile` acrescentaria 3 ou 4 flags usadas por um único chamador. É duplicação aparente, não real: é outro componente.

## Riscos / dependências

- **Risco principal: regressão silenciosa.** São 4 telas grandes (`home_screen` 736, `historico_screen` 768, `balanco_screen` 1.062, `ficha_cliente_screen` 652 linhas) sem teste de widget que cubra a lista. A mitigação é o fatiamento em duas etapas, os testes de unidade das factories e de `rotuloStatus`, e o teste manual no navegador ao fim de cada etapa (login → Home → Histórico com paginação → Balanço trocando período → Ficha de um cliente).
- **Dependência: Supabase de produção no ar.** O teste manual precisa do projeto ativo — o plano gratuito pausa por inatividade (`CLAUDE.md`, "Se o app subir mas o login falhar").
- **Sem risco de migration**: esta spec não toca no banco, então nada precisa ser rodado no SQL Editor.
- `balanco_screen.dart` e `detalhes_lancamento_screen.dart` continuam grandes ao fim da spec (o Balanço perde ~40 linhas de carga). Quebrá-los segue fora de escopo, como registrado no `requirements.md`.
