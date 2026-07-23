# Tarefas — Período Personalizado no Balanço

- [x] `balanco_screen.dart`: adicionar `_periodoPersonalizado` (`DateTimeRange?`) ao estado
- [x] `balanco_screen.dart`: `_abrirSeletorMes()` ganha item "Período personalizado..." (checkmark quando ativo); selecionar mês volta a zerar `_periodoPersonalizado`
- [x] `balanco_screen.dart`: novo `_escolherPeriodoPersonalizado()` (`showDateRangePicker`, mesmo padrão do Histórico)
- [x] `balanco_screen.dart`: novo `_rotuloPeriodo()` e `_formatarDataCurta()`; cabeçalho passa a usar `_rotuloPeriodo()`
- [x] `balanco_screen.dart`: `_carregar()` calcula `inicio`/`fimExclusivo` a partir de `_periodoPersonalizado` OU `_mes`; acumula `entradaPorDia`/`saidaPorDia` por `DateTime` (não mais `int`); monta `List<_BarraValor>` (por dia se ≤31 dias, por mês se >31 dias)
- [x] `_BalancoDados`: trocar `entradaPorDia`/`saidaPorDia`/`diasNoMes` por `barras`
- [x] `_EntradasSaidasChart`: generalizar para `List<_BarraValor> barras` em vez de dia/mês fixo
- [x] Título "LANÇAMENTOS DE..." e mensagens de vazio viram genéricas ("...DO PERÍODO"/"...neste período") quando `_periodoPersonalizado` ativo
- [x] `flutter analyze` limpo
- [x] `flutter test` passando
- [x] Commit + push
- [ ] Testado manualmente no navegador (período de poucos dias, período de ~2-3 meses cruzando virada de ano, voltar pro modo mês único)
- [x] Atualizar índice em `specs/README.md`
