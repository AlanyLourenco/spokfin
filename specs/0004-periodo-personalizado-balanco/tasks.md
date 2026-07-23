# Tarefas — Período Personalizado no Balanço

- [x] ~~`_periodoPersonalizado` (`DateTimeRange?`) + lista de 12 meses~~ (implementado, depois revisado)
- [x] Trocar `DateTime _mes` + `DateTimeRange? _periodoPersonalizado` por `String _periodo = 'todos'` + `DateTimeRange? _intervaloPersonalizado`
- [x] Substituir `_abrirSeletorMes` por `_abrirSeletorPeriodo` (4 opções, cópia do Histórico)
- [x] Ajustar `_escolherPeriodoPersonalizado()` pra setar `_periodo = 'personalizado'`
- [x] Novo `_rotuloPeriodo()` (cópia do Histórico) — cabeçalho passa a usá-lo
- [x] `_carregar()`: bounds por `_periodo` (este_mes/mes_passado/personalizado/todos sem filtro); rastrear menor/maior `data_transacao` pro caso "todos"
- [x] Granularidade do gráfico: "todos" sempre agrupa por mês, usando o intervalo dos dados carregados
- [x] Novo `_tituloLancamentos()` + mensagens de vazio por `_periodo`
- [x] `flutter analyze` limpo
- [x] `flutter test` passando
- [x] Commit + push
- [ ] Testado manualmente no navegador (Todos os meses, Este Mês, Mês Passado, Período personalizado curto e longo)
- [x] Atualizar `specs/README.md` (já indexado, só atualizar status se preciso)
