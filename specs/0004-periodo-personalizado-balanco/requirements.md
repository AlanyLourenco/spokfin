# Requisitos — Período Personalizado no Balanço

## Contexto
O Histórico já tem um seletor de período com opção "Período personalizado..." (data de início e fim escolhidas livremente via `showDateRangePicker`, dia/mês/ano dos dois lados). O Balanço só tem o seletor de mês único (`_abrirSeletorMes`, corrigido nesta mesma rodada pra não sumir com meses futuros). O usuário quer a mesma opção de período livre (data início → data fim) também no Balanço, além do seletor de mês único que já existe.

## Objetivo
No Balanço, o usuário consegue escolher um período arbitrário (dia/mês/ano de início até dia/mês/ano de fim) em vez de só um mês inteiro, e o dashboard (cards de totais, gráfico entradas/saídas, donut de categorias, lista de lançamentos) reflete esse período.

## Requisitos funcionais
- [x] ~~O seletor de mês do Balanço ganha uma opção adicional "Período personalizado..."~~ — **revisado**: o seletor do Balanço deixa de ser a lista dos últimos 12 meses e passa a ser **idêntico ao do Histórico**: "Todos os meses" / "Este Mês (mês/ano)" / "Mês Passado (mês/ano)" / "Período personalizado..." (mesmo bottom sheet, mesmas 4 opções, mesmo texto).
- [ ] Ao escolher qualquer uma das 4 opções, os cards de totais (Entradas, Saídas, Saldo), o donut de "Gastos por Categoria" e a lista de lançamentos passam a refletir o período escolhido.
- [ ] "Todos os meses" busca todos os lançamentos da empresa, sem filtro de data.
- [ ] O cabeçalho mostra o rótulo do período no mesmo formato do Histórico: nome do mês/ano pra Este Mês/Mês Passado, "dd/mm - dd/mm" pra período personalizado, "Todos os meses" pra esse caso.
- [ ] O gráfico "Entradas vs Saídas": para período de até ~1 mês, continua uma barra por dia. Para período maior que ~1 mês (inclusive "Todos os meses"), passa a ser uma barra por mês dentro do intervalo com dados (cada barra soma entradas/saídas daquele mês).

## Fora de escopo
- Não mexe no seletor de período do Histórico, que já funciona (é o modelo copiado).

## Perguntas em aberto
Nenhuma — decisão do gráfico confirmada com o usuário: agrupar por mês quando o período passar de ~1 mês.
