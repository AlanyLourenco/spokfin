# Tarefas — Alinhar o front ao protótipo (spokfin-ledger-ai)

Três etapas, cada uma fechando com `flutter analyze` limpo, `flutter test` passando e conferência no navegador contra o protótipo. Sem migration.

## Etapa 1 — Fundação (tokens, card, coluna, navegação, FAB)

- [x] `lib/theme.dart`: paleta nova (`background`, `surface`, `surfaceSunken`, `border`, `primary`, `accent`, `negative`, `textPrimary`, `textMuted`), `surfaceAlt` removido e seus usos apontados para `surface`
- [x] `lib/theme.dart`: `titleTextStyle` do `AppBar` sai da Calistoga para Inter (D3)
- [x] `lib/shared/app_card.dart`: borda sólida `border`, raio 16
- [x] `lib/shared/coluna_central.dart`: `ColunaCentral`, aplicada no `builder:` do `MaterialApp` em `main.dart`
- [x] `lib/shell/navegacao_flutuante.dart`: pílula flutuante com indicador preenchido e transição via `AppMotion`
- [x] `lib/shell/main_shell.dart`: usa a navegação nova, `extendBody: true`
- [x] `QuickActionsSpeedDial`: círculo `primary` acima da navegação (só aparência, comportamento intacto)
- [x] Home: o wordmark "spokfin" sai da Calistoga
- [x] `flutter analyze` limpo e `flutter test` passando
- [ ] Conferido no navegador lado a lado com o protótipo

## Etapa 2 — As 5 telas principais

- [ ] Home: cartão de saldo, A Receber/A Pagar, lista de recentes, linha de ações Falar/Anotar/Manual
- [ ] `LancamentoTile`: valor no formato `+$ 300.00` (sem espaço entre sinal e cifrão)
- [ ] Histórico: filtros, agrupamento por mês, busca, exportar — **sem perder** nenhum deles
- [ ] Balanço: cartões de lucro/faturamento/custos, gráfico de entradas vs saídas, donut de categoria, seletor de período (incluindo personalizado)
- [ ] MRR: cabeçalho com ATIVOS/MRR, cards de assinante
- [ ] Clientes: alternador Clientes/Fornecedores, busca, lista com avatar
- [ ] `flutter analyze` limpo e `flutter test` passando
- [ ] Cada tela conferida contra a tela equivalente do protótipo

## Etapa 3 — As telas secundárias

- [ ] Auth: login, cadastro, recuperação de senha, nova senha
- [ ] Onboarding: `EmpresaSetupScreen`
- [ ] Lançamentos: Anotar, Falar, Revisar, Detalhes (modal), Recibo
- [ ] Clientes: formulário, Ficha do Cliente, Ficha do Fornecedor, encarregado
- [ ] MRR: Ficha do Assinante, Nova Assinatura
- [ ] Perfil e Termos
- [ ] `flutter analyze` limpo e `flutter test` passando
- [ ] Varredura final: nenhuma tela com a aparência antiga

## Fechamento

- [ ] `DESIGN.md`: tokens novos, o que mudou e por quê (a regra azul = ação / verde = dinheiro **continua valendo**)
- [ ] `CLAUDE.md`: seção de cores atualizada
- [ ] `specs/README.md` e `specs/requisitos-e-cronograma.md` atualizados
- [ ] Conferir se alguma funcionalidade da lista do `requirements.md` se perdeu no caminho
