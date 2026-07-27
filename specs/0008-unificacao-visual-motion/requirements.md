# Requisitos — Unificação Visual e Motion

## Contexto

O app cresceu tela por tela (20 telas hoje) ao longo das Fases 0-2, e mesmo com extrações recentes de duplicação (`RotuloCard`, `formatarData`, `iniciaisDoNome`) o polimento visual não foi feito de forma sistemática — o resultado é um produto funcional mas com identidade visual inconsistente entre telas (espaçamento, hierarquia, uso de cor, ausência de movimento) e sem nenhuma animação além do essencial. O usuário quer elevar o app inteiro a um padrão de craft alto, com identidade visual una entre todas as telas e movimento (incluindo profundidade/3D) usado com intenção, seguindo os princípios de design de Emil Kowalski (motion sutil, com propósito, timing curto, easing customizado — não decoração gratuita).

Acabamos de instalar duas skills pra isso: **Impeccable** (crítica/polimento de UI, com fluxo próprio de `PRODUCT.md`/`DESIGN.md`) e as skills de **Emil Kowalski** (`emil-design-eng`, `review-animations`, `improve-animations`, `find-animation-opportunities`, `animation-vocabulary`, `apple-design`). `PRODUCT.md` já foi criado. Este spec cobre o trabalho de aplicar essas skills ao codebase inteiro.

## Objetivo

Todas as 20 telas do app compartilham a mesma linguagem visual documentada (`DESIGN.md`), com um padrão de polimento consistente (espaçamento, tipografia, cor, estados vazios/erro/loading) e movimento — incluindo profundidade/3D onde fizer sentido — implementado à mão (sem novas dependências), com timing e easing deliberados em vez de padrão do Flutter.

## Requisitos funcionais

- [ ] `DESIGN.md` é gerado (via `/impeccable document`) documentando o sistema visual atual (`AppColors`, `RotuloCard`, `CampoRotulado`, `AppCard`, tipografia, espaçamento) como fonte única de verdade.
- [ ] Cada uma das 20 telas é revisada (`critique`/`audit` do Impeccable) e as inconsistências encontradas (cor hardcoded fora de `AppColors`, espaçamento fora do ritmo padrão, hierarquia tipográfica inconsistente, estados de erro/vazio/loading não tratados) são corrigidas.
- [ ] Nenhuma tela usa cor, borda ou espaçamento fora do que está documentado em `DESIGN.md`/`theme.dart` (sem hex/valores mágicos soltos).
- [ ] O app ganha um vocabulário de motion consistente e reutilizável (curvas de easing e durações padronizadas, ex. em `theme.dart` ou um novo arquivo de constantes de animação), em vez de cada tela inventar a própria transição.
- [ ] Pelo menos os seguintes pontos ganham movimento com propósito (a lista final de "onde" é decidida na fase de design, usando `find-animation-opportunities`):
  - Abertura/fechamento do modal de Detalhes/Edição de Lançamento (`detalhes_lancamento_screen.dart`).
  - Cards de lista (Home, Histórico, Clientes, MRR) — entrada e interação (toque/hover no web).
  - Troca de aba no `MainShell` / abertura do `QuickActionsSpeedDial`.
  - Gráficos do Balanço (`_EntradasSaidasChart`, `_DonutChart`) — revelação animada dos dados.
- [ ] Onde fizer sentido (não em todo lugar — critério de "propósito", não decoração), movimento ganha profundidade/3D real via `Transform`/`Matrix4` (perspective, rotateX/rotateY) — não é um efeito raso de escala/opacidade disfarçado de "3D".
- [ ] Toda animação nova segue os princípios do Emil Kowalski: duração curta (referência: <300ms para a maioria das micro-interações), easing customizado (não `Curves.linear`/default do Material sem critério), e passa pela skill `review-animations` antes de ser considerada concluída.
- [ ] `flutter analyze` continua "No issues found!" e `flutter test` continua passando após as mudanças.
- [ ] Nenhuma mudança de comportamento/regra de negócio — é um trabalho de camada de apresentação. RPCs, validações e fluxos continuam idênticos.
- [ ] Testado manualmente no navegador (`flutter run -d web-server`) — golden path de cada área tocada, sem regressão visual/funcional.

## Fora de escopo

- Nenhuma dependência nova (sem pacote de animação/3D — tudo à mão, como já é convenção do projeto).
- Nenhuma mudança de schema, RPC ou lógica de backend.
- Nenhum trabalho específico para Android/iOS nativo — o alvo é o app web (Flutter web), plataforma confirmada em `PRODUCT.md`.
- Reescrever copy/textos das telas (a não ser que um erro de clareza seja encontrado incidentalmente durante o polimento) — isso seria um spec de UX copy separado.
- Novas features/funcionalidades — é polimento e consistência do que já existe, não novas telas ou fluxos.

## Perguntas em aberto

- Dado que são 20 telas, a implementação (`tasks.md`) vai ser dividida em lotes (ex.: sistema de design primeiro, depois telas por área — Home/Balanço/MRR/Histórico/Clientes/Lançamentos/Auth/Perfil) em vez de uma tarefa monolítica. Cada lote é validado (`flutter analyze` + teste manual) antes do próximo.
- A ordem sugerida de execução por lote fica definida no `design.md` — se o usuário tiver uma prioridade de tela (ex. "Home primeiro"), avisar antes do design.
