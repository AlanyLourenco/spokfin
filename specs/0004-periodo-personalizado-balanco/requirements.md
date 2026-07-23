# Requisitos — Período Personalizado no Balanço

## Contexto
O Histórico já tem um seletor de período com opção "Período personalizado..." (data de início e fim escolhidas livremente via `showDateRangePicker`, dia/mês/ano dos dois lados). O Balanço só tem o seletor de mês único (`_abrirSeletorMes`, corrigido nesta mesma rodada pra não sumir com meses futuros). O usuário quer a mesma opção de período livre (data início → data fim) também no Balanço, além do seletor de mês único que já existe.

## Objetivo
No Balanço, o usuário consegue escolher um período arbitrário (dia/mês/ano de início até dia/mês/ano de fim) em vez de só um mês inteiro, e o dashboard (cards de totais, gráfico entradas/saídas, donut de categorias, lista de lançamentos) reflete esse período.

## Requisitos funcionais
- [ ] O seletor de mês do Balanço (`_abrirSeletorMes`) ganha uma opção adicional "Período personalizado...", igual à do Histórico, abrindo um `showDateRangePicker`.
- [ ] Ao escolher um período personalizado, os cards de totais (Entradas, Saídas, Saldo), o donut de "Gastos por Categoria" e a lista "Lançamentos do Período" passam a refletir o intervalo escolhido (não mais um mês calendário fixo).
- [ ] O cabeçalho mostra o período escolhido por extenso (ex: "01/03/2026 - 15/04/2026"), no mesmo formato usado no rótulo de período personalizado do Histórico.
- [ ] Ainda é possível voltar a navegar por mês único a qualquer momento (o seletor continua oferecendo os últimos 12 meses, mais a opção de período personalizado).
- [ ] O gráfico "Entradas vs Saídas": para período de até ~1 mês, continua uma barra por dia (comportamento atual). Para período maior que ~1 mês, passa a ser uma barra por mês dentro do intervalo (cada barra soma entradas/saídas daquele mês, incluindo meses parciais nas pontas do período).

## Fora de escopo
- Não mexe no seletor de período do Histórico, que já funciona.
- Não adiciona atalhos tipo "Este Mês"/"Mês Passado" ao Balanço — o seletor de mês único já cobre isso ao listar os últimos 12 meses.

## Perguntas em aberto
Nenhuma — decisão do gráfico confirmada com o usuário: agrupar por mês quando o período passar de ~1 mês.
