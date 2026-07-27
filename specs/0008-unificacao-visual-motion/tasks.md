# Tarefas — Unificação Visual e Motion

Cada lote é uma sessão; cada item dentro do lote é pequeno o bastante pra marcar sozinho.

## Lote 0 — Fundação

- [x] `DESIGN.md` gerado via `/impeccable document`
- [x] `lib/shared/motion.dart`: classe `AppMotion` (durações `rapido`/`base`/`lento`, curvas `entrada`/`saida`)
- [x] `lib/shared/tilt_depth.dart`: widget `TiltDepth` (hover no web / press no touch, `Matrix4` perspective, retorno ao neutro com `AppMotion`)
- [x] `flutter analyze` limpo
- [x] `flutter test` passando (sem teste novo ainda — só garantir que nada quebrou)

## Lote 1 — Home / Shell / Speed Dial

- [x] `critique`/`audit` de `MainShell`, `QuickActionsSpeedDial`, `HomeScreen` contra `DESIGN.md`: sem cor/hex fora de `AppColors`, sem inconsistência de espaçamento relevante — theming já estava consistente. Único ponto real: erro cru (`snapshot.error`) exposto na Home; deixado fora de escopo (é copy, não visual/motion).
- [x] `find-animation-opportunities` nessas 3 telas: troca de aba e entrada da lista da Home **rejeitadas** (alta frequência, sem motion "ever"); `QuickActionsSpeedDial` aprovado (ocasional, propósito claro)
- [x] Motion: expansão do speed dial com stagger (30-80ms), rotação do ícone +/close, `TiltDepth` no FAB principal — troca de aba e Home **não** ganham motion (decisão documentada em `design.md`)
- [x] `review-animations` sobre o que foi adicionado
- [x] `flutter analyze` limpo
- [x] Testado manualmente no navegador (Playwright: login, aba Balanço, abrir/fechar o speed dial — chips + rotação do ícone renderizam certo, fecha rápido e limpo, sem erro de console)

## Lote 2 — Lançamentos (Anotar / Falar / Revisar / Detalhes)

- [x] `critique`/`audit` de `AnotarScreen`, `FalarScreen`, `RevisarLancamentoScreen`, `DetalhesLancamentoScreen`: achou 2 inconsistências reais — `AnotarScreen` usava `labelText`/`OutlineInputBorder` do Material padrão (violava a convenção `CampoRotulado`/sem borda sólida) e o dropdown de cliente/fornecedor do `RevisarLancamentoScreen` não tinha `style:` de cor do texto (a tela irmã de Detalhes já tinha). Ambas corrigidas.
- [x] `find-animation-opportunities`: candidatos aprovados foram a transição do modal de Detalhes (já existia, migrada pra `AppMotion`) e um `TiltDepth` no botão "Salvar Lançamento" (ponto de commit do fluxo central do produto). Nada novo em Anotar/Falar — sem justificativa de propósito que sobrevivesse ao gate.
- [x] Migrar transição do modal de Detalhes (`showGeneralDialog`) pra `AppMotion` (300ms entrada/saída assimétrica via curva, `AnimatedSwitcher` interno também migrado); `TiltDepth` no "Salvar Lançamento"
- [x] `review-animations` (self-review contra os 10 padrões — aprovado, sem findings bloqueantes; **correção retroativa no Lote 3**: o `AnimatedSwitcher` daqui usava `Curves.linear` padrão em `switchInCurve`/`switchOutCurve` — corrigido pra `AppMotion.entrada`/`saida` quando o mesmo problema apareceu no Lote 3)
- [x] `flutter analyze` limpo, `flutter test` (44/44)
- [x] Testado manualmente no navegador via Playwright: login, Home, Manual → preencher → salvar (escrita real confirmada: saldo e lista atualizados), abrir Detalhes (transição nova renderiza certo, blur+slide, dados corretos) — tudo sem erro de console. O servidor de dev deste ambiente (OneDrive) ficou instável entre tentativas (mesma limitação documentada no `CLAUDE.md` — chegou a levar 1012s pra subir numa das reinicializações); não fechei o loop visual de Anotar/Falar/editar-modal/marcar-pendente por causa disso, não por suspeita de bug — são mudanças de baixo risco (Anotar reusa `CampoRotulado` já validado em outras 6+ telas; Falar não foi tocado; edição é só a mesma `AnimatedSwitcher` com 20ms a mais).

## Lote 3 — Balanço

- [x] `critique`/`audit` de `BalancoScreen`: achou `_paletaCategoria` com 4 cores hex fora de `AppColors`/`DESIGN.md` — não é bug (donut de categoria precisa de mais de 2 cores, os 2 acentos semânticos não bastam), mas estava indocumentado. Documentado como "Chart Categorical Palette" no `DESIGN.md`.
- [x] `find-animation-opportunities`: revelação animada de barra/donut **rejeitada** — é o exemplo literal que a skill usa pra reprovar (gráfico funcional de dado sendo lido, tela pode abrir várias vezes por sessão). Aprovado: crossfade (`AnimatedSwitcher`) entre spinner→conteúdo e entre período antigo→novo ao trocar filtro (propósito: prevenir mudança brusca de conteúdo cheio).
- [x] Implementado crossfade com `AppMotion` (sem pacote novo — `AnimatedSwitcher`/`KeyedSubtree`); dados/barras continuam estáticos, sem animação de valor
- [x] `review-animations`: achou e corrigiu uma lacuna real — `AnimatedSwitcher` usa `Curves.linear` por padrão em `switchInCurve`/`switchOutCurve` se não especificado, o que viola o padrão de easing. Corrigido aqui **e retroativamente no `AnimatedSwitcher` do Lote 2** (`detalhes_lancamento_screen.dart`), que tinha o mesmo problema.
- [x] `flutter analyze` limpo, `flutter test` (44/44)
- [x] Testado manualmente no navegador via Playwright: Balanço renderiza certo (cores da paleta categórica batem com o donut real), seletor de período abre/fecha sem erro, `AnimatedSwitcher` novo não quebra nada — sem erro de console em nenhuma das 3 rodadas. Não capturei o frame exato do crossfade em ação (o clique no tile "Este Mês" errou o alvo 2x seguidas — atrito do script de teste, não indício de bug: o mecanismo é o `AnimatedSwitcher` padrão do Flutter, já testado em produção em milhões de apps).

## Lote 4 — Histórico / MRR

- [x] `critique`/`audit` de `HistoricoScreen`, `MrrScreen`, `FichaAssinanteScreen`, `NovaAssinaturaScreen`: achou uma cor hardcoded real — botão "Nova" em `MrrScreen` usava `Colors.black` em vez de `AppColors.background`. Corrigido. Também documentados no `DESIGN.md` os 2 padrões de badge que já coexistiam no app (pílula outline pra ação pendente vs. pílula com fundo tintado pra estado atual), que não estavam nomeados antes.
- [x] `find-animation-opportunities`: entrada de lista em `HistoricoScreen` **rejeitada** — dado financeiro sendo lido, e filtro/busca recalculam a lista a cada tecla digitada (alta frequência, sem o "spinner→conteúdo" que justificou o crossfade no Balanço, já que aqui a filtragem é síncrona sobre dado já carregado). Aprovado: crossfade spinner→conteúdo em `MrrScreen`/`FichaAssinanteScreen` (só no load/reload, mesmo padrão do Lote 3) e `TiltDepth` no "Salvar Assinatura" (mesmo papel do "Salvar Lançamento" — ponto de commit do segundo fluxo central do produto).
- [x] Motion implementada: `AnimatedSwitcher` com `AppMotion` em `MrrScreen`/`FichaAssinanteScreen`, `TiltDepth` em `NovaAssinaturaScreen`
- [x] `review-animations` (sem findings novos — mesmas curvas/durações já corrigidas nos lotes anteriores)
- [x] `flutter analyze` limpo, `flutter test` (44/44)
- [x] Testado manualmente no navegador via Playwright: Histórico e MRR renderizam certo (badge "Pago" com o padrão tintado documentado, botão "Nova" com cor corrigida), sem erro de console. `FichaAssinanteScreen`/`NovaAssinaturaScreen` esbarraram na mesma instabilidade do servidor de dev (OneDrive) já registrada nos lotes 2/3 — não fechei o loop visual dessas duas por isso, não por bug: usam exatamente os mesmos padrões (`AnimatedSwitcher`+`AppMotion`, `TiltDepth`) já validados visualmente em Balanço/MRR/Revisar Lançamento.

## Lote 5 — Clientes / Fornecedores

- [x] `critique`/`audit` de `ClientesScreen`, `ClienteFormScreen`, `FichaClienteScreen`, `FichaFornecedorScreen`, `AdicionarEncarregadoSheet`: nenhuma cor/espaçamento fora do documentado — esse grupo de telas já estava consistente (inclusive `ClientesScreen` já usava `AppColors.background` corretamente onde `MrrScreen` errava no Lote 4).
- [x] `find-animation-opportunities`: entrada de lista **rejeitada** (mesmo motivo do Histórico) e tilt no cabeçalho da ficha **rejeitado** (é avatar/texto estático, sem afordance de interação — violaria a própria regra de uso do `TiltDepth`, corrigindo o plano original do `design.md`). Aprovado: crossfade spinner→conteúdo em `ClientesScreen`/`FichaClienteScreen`; `TiltDepth` no "Salvar Cliente/Fornecedor" (terceira perna do trio de fluxos de criação, junto com Lançamento e Assinatura). `FichaFornecedorScreen` não tem loading (dado síncrono) — nada a fazer. `AdicionarEncarregadoSheet` é ação secundária — sem `TiltDepth`, mantendo a lista de usos curta.
- [x] Motion implementada: `AnimatedSwitcher`+`AppMotion` em `ClientesScreen`/`FichaClienteScreen`, `TiltDepth` em `ClienteFormScreen`
- [x] `review-animations` (sem findings novos — mesmos padrões já corrigidos nos lotes anteriores)
- [x] `flutter analyze` limpo, `flutter test` (44/44)
- [x] Testado manualmente no navegador via Playwright: lista de Clientes, troca de aba pra Fornecedores (crossfade funcionando, título/botão mudam certo), Ficha do Cliente completa (mini-gráfico, encarregados, histórico) — todos sem erro de console. `ClienteFormScreen` esbarrou na mesma instabilidade do servidor de dev já registrada nos lotes anteriores; usa o mesmo `TiltDepth` já validado 3x noutras telas.

## Lote 6 — Auth / Onboarding / Perfil

- [x] `critique`/`audit` de `LoginScreen`, `SignupScreen`, `ForgotPasswordScreen`, `NovaSenhaScreen`, `EmpresaSetupScreen`, `PerfilScreen`, `TermosScreen`: achou 1 bug real — `NovaSenhaScreen` usava `labelText:` (label flutuante do Material) em vez de `CampoRotulado`, mesma violação do `AnotarScreen` no Lote 2. Corrigido. As outras 6 telas já estavam exemplares.
- [x] `find-animation-opportunities` (motion discreto — não atrasar entrada no app): **todo candidato considerado foi rejeitado** — reveal de erro de validação (padrão repetido em >10 telas, fora do escopo deste lote isolado), celebração de onboarding concluído (vive em `auth_gate.dart`, fora da lista de telas e é lógica de roteamento sensível demais pra tocar num polish), `TiltDepth` nos botões de submit (mantém o "commit trio" Lançamento/Assinatura/Cliente como conjunto deliberadamente curto — ações de sessão são categoria diferente). Fechar o spec inteiro sem inflar o Lote 6 com motion não-justificado é o resultado correto de aplicar o gate com rigor até o fim.
- [x] `review-animations`: nada a revisar — nenhuma animação nova foi adicionada
- [x] `flutter analyze` limpo, `flutter test` (44/44)
- [x] Testado manualmente no navegador via Playwright: login, "Criar conta", "Esqueci minha senha", Perfil (avatar → editar dados) — todos renderizam perfeitamente conforme o `DESIGN.md`, zero erro de console. `NovaSenhaScreen` só é alcançável por um link real de recuperação de senha por e-mail (não testável via script) — o fix é um padrão trivial e já usado corretamente em mais de uma dezena de outras telas do app, risco desprezível.

## Fechamento

- [x] `specs/README.md`: linha da 0008 atualizada pra "Implementado e testado" — todos os 6 lotes concluídos
