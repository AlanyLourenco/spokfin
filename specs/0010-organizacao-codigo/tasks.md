# Tarefas — Organização do código: modelo e componentes de lançamento unificados

Duas etapas, cada uma fechando com `flutter analyze` limpo e `flutter test` passando. Sem migration: nada para rodar no SQL Editor nesta spec.

## Etapa 1 — Modelo e repositório

- [x] `lib/lancamentos/status_lancamento.dart`: `rotuloStatus`, `corStatus`, `iconeStatus`
- [x] `lib/lancamentos/lancamento_detalhado.dart`: factories `deTransacao`/`deConta` + getters `pago`, `entrada`, `statusLabel`
- [x] `lib/lancamentos/lancamentos_repository.dart`: `buscarLancamentos`, `buscarPaginaLancamentos`, `buscarVencendoEmBreve`, `PaginaLancamentos` e o helper privado de resolução de nome de cliente
- [x] `test/lancamento_detalhado_test.dart`: factories (conversão de data, `receber`→`entrada`, nulos → `''`, `status_efetivo` ausente cai para `status`) e `rotuloStatus` nos 4 estados
- [x] Home: apagar `_LancamentoResumo` e a carga própria; usar `buscarLancamentos` + `buscarVencendoEmBreve`; `_LancamentoTile` passa a receber `LancamentoDetalhado`
- [x] Histórico: apagar `_Item` e `_buscarPagina`; usar `buscarPaginaLancamentos(ignorarCancelados: true)`; `_ItemTile` passa a receber `LancamentoDetalhado`
- [x] Balanço: apagar `_LancamentoMes`; usar `buscarLancamentos(incluirContas: false)` e agregar em cima da lista retornada (manter a normalização de categoria vazia → `Outros` via `copiarCom`); `_abrirDetalhes` deixa de reconstruir o modelo à mão
- [x] Ficha do Cliente: apagar `_ItemHistorico`; usar `buscarLancamentos(clienteId:, incluirContasPagas: true)`; manter o tile compacto próprio e a exibição por `pago` (DV5)
- [x] MRR: `_AssinaturaTile` consome `rotuloStatus`/`corStatus` em vez da tradução local
- [x] Detalhes do lançamento: consome `rotuloStatus` (mantém a cor local — DV4)
- [x] `flutter analyze` limpo e `flutter test` passando
- [x] Testado manualmente no navegador (03/09/2026): Home, Histórico, Balanço e Ficha do Cliente carregam com dado real, sem erro. Home mostra o subtítulo `Pago` / `Serviço · Pago` (categoria omitida quando vazia); Histórico mostra ícone de status + `data · categoria` + borda hairline; Balanço fecha em faturamento $3.010 − custos $7.450 = −$4.440, **igual ao saldo calculado pela RPC `calcular_saldo`**, que esta spec não tocou — evidência de que o laço de agregação reescrito dá o mesmo resultado; Ficha do Cliente traz Total Pago R$ 2.710,00 / 7 serviços e o tile compacto próprio (bolinha + `formatarMoeda`)
- [ ] **Não verificado**: "Carregar mais" do Histórico (a base tem poucos lançamentos, o botão não chega a aparecer), a troca de período do Balanço e a lista de lançamentos do Balanço — a rolagem dentro do canvas do Flutter não responde a evento sintético do navegador. Depende de rolar à mão, ou do dado de exemplo da spec `0011`
- [ ] **Não verificado**: a lista "Vencendo em breve" da Home — a base não tem conta pendente (A Receber e A Pagar estão em $ 0,00)

## Etapa 2 — Componentes visuais

- [x] `lib/lancamentos/lancamento_tile.dart`: `LancamentoTile` + `PilulaNotaFiscal`, com os parâmetros do `design.md` e cada flag de divergência comentada com seu `DV#`
- [x] Home: `_LancamentoTile` apagado, chamadas trocadas por `LancamentoTile` (`emDestaque: true`, `pilulaComIcone: true`, subtítulo `categoria · status`)
- [x] Histórico: `_ItemTile` apagado (`mostrarIconeStatus: true`, `comBordaInferior: true`, subtítulo `data · categoria`)
- [x] Balanço: `_LancamentoMesTile` apagado (`comBordaInferior: true`, `mostrarNotaFiscal: false`, subtítulo `data · Pago · categoria`)
- [x] `flutter analyze` limpo e `flutter test` passando
- [ ] ~~Comparação visual com os prints de antes~~ — não há prints de referência das três telas no repositório (`prints/` tem só um arquivo solto); a verificação visual acontece no teste manual abaixo
- [ ] Testado manualmente no navegador (mesmo roteiro da Etapa 1)

## Fechamento

- [x] `CLAUDE.md`: registrar o modelo/repositório/tile unificados como a convenção para tela nova que liste lançamento
- [x] `specs/README.md`: linha da spec `0010` com o status final
- [x] `specs/requisitos-e-cronograma.md`: item correspondente atualizado
- [x] Reportar ao usuário as divergências DV1-DV6 e perguntar se viram spec `0011`
