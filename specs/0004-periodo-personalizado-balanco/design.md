# Design — Período Personalizado no Balanço

## Modelagem de dados
Nenhuma mudança de schema. Só uma nova query em `transacoes` com `gte`/`lt` sobre um intervalo arbitrário em vez de sempre o 1º dia ao último dia do `_mes` selecionado — mesma tabela, mesmas colunas.

## Backend
Nenhuma mudança. Continua uma query direta com `.gte('data_transacao', ...).lt('data_transacao', ...)`, só que os limites passam a vir de `_periodoPersonalizado` (quando setado) em vez de sempre derivados de `_mes`.

## Telas / UI

### Estado (`_BalancoScreenState`)
- Novo campo `DateTimeRange? _periodoPersonalizado` (mutuamente exclusivo com o modo "mês único" — quando não-nulo, tem prioridade).
- `_abrirSeletorMes()` ganha mais um `ListTile` no fim da lista, "Período personalizado...", com checkmark quando `_periodoPersonalizado != null`. Ao tocar, fecha o bottom sheet e chama `_escolherPeriodoPersonalizado()` (novo método, cópia do padrão já usado em `historico_screen.dart:_escolherPeriodoPersonalizado`: `showDateRangePicker` com `firstDate`/`lastDate` de -5/+1 anos, `initialDateRange: _periodoPersonalizado`).
- Selecionar um mês da lista (`ListTile` de mês já existente) volta a zerar `_periodoPersonalizado = null`, restaurando o modo mês único.
- Rótulo do cabeçalho (`_rotuloPeriodo()`, novo método): se `_periodoPersonalizado != null`, retorna `'${_formatarDataCurta(inicio)} - ${_formatarDataCurta(fim)}'` — mesmo formato dd/mm (sem ano) que `historico_screen.dart` já usa, por consistência entre as duas telas. Senão, o rótulo de mês atual (`'${_nomesMesesCompletos[_mes.month-1]} de ${_mes.year}'`).
- Título "LANÇAMENTOS DE {MÊS} DE {ANO}" e as duas mensagens de estado vazio ("Nenhum gasto registrado neste mês" / "Nenhum lançamento neste mês") passam a checar `_periodoPersonalizado`: se ativo, viram "LANÇAMENTOS DO PERÍODO" / "...neste período".

### `_carregar()`
- Calcula `inicio`/`fimExclusivo` a partir de `_periodoPersonalizado` (quando setado) ou do `_mes` (comportamento atual), como hoje.
- `duracaoDias = fimExclusivo.difference(inicio).inDays`. Define `agruparPorMes = duracaoDias > 31`.
- Durante o loop que já existe sobre as `transacoes` (que calcula `receitas`, `despesas`, `categoriaTotais`, `lancamentos`), acumula também `entradaPorDia`/`saidaPorDia` como `Map<DateTime, double>` chaveado pela data (ano/mês/dia, sem hora) — evita colisão entre dias de meses diferentes que o `Map<int, double>` atual (chave só o dia do mês) teria se o período cruzar meses.
- Depois do loop, monta a lista final de barras do gráfico (`List<_BarraValor>`, tipo novo — ver abaixo):
  - Se `!agruparPorMes`: uma `_BarraValor` por dia dentro de `[inicio, fimExclusivo)`, rótulo `dd/mm`.
  - Se `agruparPorMes`: agrega `entradaPorDia`/`saidaPorDia` por `DateTime(ano, mês)` e gera uma `_BarraValor` por mês dentro do intervalo (incluindo meses parciais nas pontas), rótulo abreviado do mês (`Fev`, `Mar`, ...), com ano junto quando o período cruza a virada do ano.

### `_EntradasSaidasChart` (generalizado)
Troca `entradaPorDia`/`saidaPorDia`/`diasNoMes` por um único `List<_BarraValor> barras` (`_BarraValor { rotulo, entrada, saida }`), e itera `barras` em vez de `1..diasNoMes` — mesmo desenho (duas barrinhas coladas por item, altura proporcional ao máximo), só que agora agnóstico a "é dia ou é mês". A faixa de rótulos embaixo (hoje fixa em "01 / meio / diasNoMes") passa a mostrar `barras.first.rotulo` / `barras[barras.length ~/ 2].rotulo` / `barras.last.rotulo`.

`_BalancoDados` troca os campos `entradaPorDia`/`saidaPorDia`/`diasNoMes` por `List<_BarraValor> barras`.

## Decisões técnicas e alternativas consideradas
- **Generalizar `_EntradasSaidasChart` para uma lista de barras genérica** em vez de manter dois widgets separados (um por dia, um por mês): evita duplicar o desenho do gráfico (que já é responsivo via `Expanded`) só pra trocar a unidade do eixo X. A lógica de "por dia ou por mês" fica isolada em `_carregar()`, o widget de UI não precisa saber a diferença.
- **Chave de agregação por `DateTime` (ano/mês/dia ou ano/mês) em vez de `int` (dia do mês)**: o `Map<int, double>` atual (chave = dia 1-31) já seria ambíguo num período que cruza meses — dia 5 de fevereiro e dia 5 de março cairiam na mesma chave. Trocar pra `DateTime` como chave resolve isso e é necessário de qualquer forma pra dar suporte a período arbitrário.
- **Limite de 31 dias pra decidir "agrupar por mês"**: alinhado com a decisão já confirmada — período de até ~1 mês continua por dia, maior que isso agrupa por mês. `> 31` cobre até o mês mais longo (31 dias) sem forçar agrupamento num mês cheio.

## Riscos / dependências
Nenhum novo — mesma tabela `transacoes`, mesma RLS, mesmo padrão de `showDateRangePicker` já validado em Histórico.
