# Design — Período Personalizado no Balanço

> Revisado: a primeira versão deste design (lista dos últimos 12 meses + item "Período personalizado..." pendurado no fim) foi implementada, mas o usuário quer o seletor do Balanço **idêntico** ao do Histórico. Esta versão substitui a anterior.

## Modelagem de dados
Nenhuma mudança de schema. Só o formato da query em `transacoes` muda: com filtro `gte`/`lt` (Este Mês, Mês Passado, Período personalizado) ou sem filtro nenhum de data (Todos os meses).

## Backend
Nenhuma mudança.

## Telas / UI

### Estado (`_BalancoScreenState`)
Troca completamente o modelo anterior (`DateTime _mes` + `DateTimeRange? _periodoPersonalizado`) pelo mesmo modelo já usado em `historico_screen.dart`:
- `String _periodo = 'todos'` (valores: `'todos'`, `'este_mes'`, `'mes_passado'`, `'personalizado'`).
- `DateTimeRange? _intervaloPersonalizado`.

### Seletor (`_abrirSeletorPeriodo`, substitui `_abrirSeletorMes`)
Cópia exata do bottom sheet de `historico_screen.dart:_abrirSeletorPeriodo` (linhas ~242-300): 4 `ListTile`s — "Todos os meses", "Este Mês (`{mês} {ano}`)", "Mês Passado (`{mês} {ano}`)", "Período personalizado..." — cada um com checkmark quando é o `_periodo` ativo. Tocar em qualquer um dos 3 primeiros chama `setState(() => _periodo = valor)` e fecha o sheet; tocar em "Período personalizado..." fecha o sheet e abre `_escolherPeriodoPersonalizado()` (já implementado na rodada anterior, mantém-se igual — só passa a setar `_periodo = 'personalizado'` em vez de um campo próprio).

### Rótulo do cabeçalho (`_rotuloPeriodo`)
Cópia do `historico_screen.dart:_rotuloPeriodo` (linhas ~302-316): `switch (_periodo)` retornando `'{mês} {ano}'` pra este_mes/mes_passado, `'{dd/mm} - {dd/mm}'` pra personalizado, `'Todos os meses'` como default.

### `_carregar()`
Calcula `inicio`/`fim` (ambos `DateTime?`, nulos só no caso `'todos'`) a partir de `_periodo`:
- `'este_mes'`: 1º dia do mês atual → 1º dia do mês seguinte.
- `'mes_passado'`: 1º dia do mês anterior → 1º dia do mês atual.
- `'personalizado'`: `_intervaloPersonalizado!.start`/`.end` (fim exclusivo = end + 1 dia), como já implementado.
- `'todos'`: `inicio`/`fim` nulos — a query não aplica `.gte`/`.lt`, busca todas as `transacoes` da empresa.

Query: monta o `PostgrestFilterBuilder` base (`.from('transacoes').select().eq('empresa_id', ...)`) e só encadeia `.gte()`/`.lt()` quando `inicio`/`fim` não são nulos, antes do `.order()`.

Granularidade do gráfico:
- Quando `inicio`/`fim` não são nulos: mesma regra já implementada (`fim.difference(inicio).inDays > 31` → agrupa por mês).
- Quando `'todos'` (sem `inicio`/`fim` fixos): agrupa por mês sempre, usando como intervalo de barras o mês da menor até o mês da maior `data_transacao` entre as transações carregadas (rastreado no mesmo loop que já calcula `receitas`/`despesas`/`categoriaTotais`). Se não houver nenhuma transação, `barras` fica vazio (o `_EntradasSaidasChart` já lida com lista vazia).

### Título "LANÇAMENTOS..." e mensagens de vazio
Viram uma função `_tituloLancamentos()`: `'LANÇAMENTOS DE {mês} DE {ano}'` pra este_mes/mes_passado (com o mês resolvido, não mais `_mes`), `'LANÇAMENTOS DO PERÍODO'` pra personalizado, `'TODOS OS LANÇAMENTOS'` pra todos. Mensagens de vazio seguem o mesmo padrão (`'...neste mês'` / `'...neste período'` / `'...ainda'`).

## Decisões técnicas e alternativas consideradas
- **Copiar o modelo de estado do Histórico em vez de adaptar o que já existia no Balanço**: são exatamente as mesmas 4 opções com o mesmo texto — manter dois modelos de estado parecidos, porém distintos (`_mes`/`_periodoPersonalizado` vs `_periodo`/`_intervaloPersonalizado`) pras duas telas seria inconsistência sem motivo. Copiar o padrão já validado no Histórico é mais simples e mantém as duas telas previsíveis.
- **"Todos os meses" sem filtro de data na query**: mais simples que buscar um intervalo artificialmente grande (ex: "últimos 10 anos"); para uma MEI o volume total de `transacoes` é pequeno o bastante pra isso não ser um problema de performance.
- **Intervalo de barras pra "Todos os meses" derivado dos dados carregados** (não de `DateTime.now()` ou de uma data fixa): evita gerar dezenas de barras vazias caso a empresa só tenha lançamentos recentes, e não trava se não houver nenhum lançamento ainda.

## Riscos / dependências
Nenhum novo.
