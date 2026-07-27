# Design — Unificação Visual e Motion

## Modelagem de dados

Nenhuma. Este spec é puramente de camada de apresentação — sem tabelas, colunas ou RLS novos.

## Backend

Nenhum. Sem RPCs, Edge Functions ou regra de negócio nova ou alterada.

## Sistema de design (fundação — Lote 0)

1. **`DESIGN.md`** gerado via `/impeccable document`, documentando o que já existe em `theme.dart`/`AppCard`/`CampoRotulado`/`RotuloCard` como fonte única de verdade. Vira a referência que toda revisão de tela usa para decidir "isso está consistente ou não".
2. **`lib/shared/motion.dart`** (novo arquivo, sem dependência nova) — classe `AppMotion` com constantes estáticas reutilizadas em todo o app, no lugar de cada tela inventar sua própria duração/curva:
   - `AppMotion.rapido` (~150ms), `AppMotion.base` (~220ms), `AppMotion.lento` (~300ms) como `Duration`.
   - `AppMotion.entrada` / `AppMotion.saida` como `Curve` customizadas (`Cubic(...)`, estilo "easeOutExpo"/"easeInExpo" — não `Curves.easeInOut` genérico do Material), seguindo o princípio do Emil Kowalski de easing com intenção em vez de default.
   - Revisado pela skill `animation-vocabulary` pra garantir que os nomes/valores batem com o vocabulário usado pelas outras skills de motion.
3. **`lib/shared/tilt_depth.dart`** (novo, sem dependência nova) — widget `TiltDepth` que envolve um `child` e aplica um `Transform` com `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(...)..rotateY(...)` proporcional à posição do ponteiro (web: hover; mobile: pressão), com `AnimatedContainer`/`TweenAnimationBuilder` usando `AppMotion` para voltar ao neutro ao sair. É o único mecanismo de "3D" do app — não introduzimos WebGL/Three.js/pacote de 3D, é tudo `Matrix4` do Flutter puro, coerente com a convenção de "sem dependência por reflexo" já em `CLAUDE.md`.
4. Critério de uso do `TiltDepth`: só em elementos com afordance de interação real (cards clicáveis de lista, o botão principal do `QuickActionsSpeedDial`) — nunca em texto estático, nunca em todos os cards da tela ao mesmo tempo. Isso é decidido tela a tela na revisão (`find-animation-opportunities`), não aplicado em bloco.

## Telas / UI — lotes de execução

Cada lote é implementado, validado (`flutter analyze` limpo + teste manual no navegador) e só então o próximo começa. Ordem por visibilidade/risco:

| Lote | Telas | Foco de motion |
|---|---|---|
| 0 | `theme.dart`, `motion.dart` (novo), `tilt_depth.dart` (novo), `DESIGN.md` | Fundação — nenhuma tela de usuário ainda |
| 1 | `MainShell`, `QuickActionsSpeedDial`, `HomeScreen` | **Correção pós-`find-animation-opportunities`**: troca de aba e entrada dos cards da Home são ações de altíssima frequência (navegação principal, tela aberta dezenas de vezes/dia) — o gate de frequência do Emil Kowalski rejeita motion aí (ver "Reject. No animation. Ever." para navegação core). Motion deste lote fica só na expansão do `QuickActionsSpeedDial` (ação ocasional, propósito claro: indicação de estado + consistência espacial), incluindo o `TiltDepth` no botão principal. |
| 2 | `AnotarScreen`, `FalarScreen`, `RevisarLancamentoScreen`, `DetalhesLancamentoScreen` | O modal de Detalhes já tem transição (`showGeneralDialog` + blur, 260ms, `easeOutCubic`) — migrar sua duração/curva pra `AppMotion` em vez de valor solto; avaliar tilt no card de resumo |
| 3 | `BalancoScreen` (`_EntradasSaidasChart`, `_DonutChart`) | **Correção pós-`find-animation-opportunities`**: crescimento animado de barra/arco foi **rejeitado** — é exatamente o exemplo que a própria skill cita pra reprovar ("gráfico funcional de dados que o usuário está lendo; decoração atrapalha", regra de Função) e a tela pode ser aberta várias vezes por sessão (não é "raro"). Único candidato aprovado: crossfade (`AnimatedSwitcher`) entre spinner→conteúdo e entre painel do período antigo→novo ao trocar filtro — troca de conteúdo cheia sem ponte, ocasional, propósito de "prevenir mudança brusca". Os valores/barras em si continuam estáticos, sem animação de dado. Sem `TiltDepth` nesta tela — não há ação de "commit", só leitura/navegação. |
| 4 | `HistoricoScreen`, `MrrScreen`, `FichaAssinanteScreen`, `NovaAssinaturaScreen` | **Correção pós-`find-animation-opportunities`**: entrada de lista **rejeitada** em `HistoricoScreen` — é dado financeiro que o usuário está lendo, e filtro/busca mudam o conteúdo a cada tecla digitada (alta frequência, gate reprova). Aprovado: crossfade spinner→conteúdo em `MrrScreen`/`FichaAssinanteScreen` (mesmo padrão do Lote 3, só no load/reload — não há filtro instantâneo aqui como no Histórico) e `TiltDepth` no "Salvar Assinatura" (mesmo papel do "Salvar Lançamento" no Lote 2 — ponto de commit do segundo fluxo central do produto). |
| 5 | `ClientesScreen`, `ClienteFormScreen`, `FichaClienteScreen`, `FichaFornecedorScreen`, `AdicionarEncarregadoSheet` | **Correção pós-`find-animation-opportunities`**: entrada de lista **rejeitada** (mesmo motivo do Histórico — dado sendo lido, busca por tecla). Tilt no cabeçalho da ficha **rejeitado** — é texto/avatar estático, sem afordance de interação real, violaria a própria regra de uso do `TiltDepth`. Aprovado: crossfade spinner→conteúdo em `ClientesScreen`/`FichaClienteScreen` (mesmo padrão dos lotes 3-4); `TiltDepth` no "Salvar Cliente/Fornecedor" de `ClienteFormScreen` (terceira perna do trio de fluxos de criação: lançamento, assinatura, cliente/fornecedor). `FichaFornecedorScreen` não tem estado de loading (dado já vem síncrono) — nada a fazer ali. `AdicionarEncarregadoSheet` é uma ação secundária (não um dos 3 fluxos centrais) — sem `TiltDepth`, mantendo a lista curta. |
| 6 | `LoginScreen`, `SignupScreen`, `ForgotPasswordScreen`, `NovaSenhaScreen`, `EmpresaSetupScreen`, `PerfilScreen`, `TermosScreen` | **Correção pós-`find-animation-opportunities`**: todo candidato de motion considerado foi **rejeitado**. Reveal animado de erro de validação — rejeitado por escopo (é um padrão repetido em >10 telas do app, incluindo fora deste lote; endereçar isoladamente aqui criaria inconsistência, mereceria seu próprio spec). Celebração na conclusão do onboarding (`EmpresaSetupScreen` → `MainShell`) — rejeitado porque a transição vive em `auth_gate.dart`, fora da lista de telas deste lote, e é lógica de roteamento sensível (recuperação de senha, gate de empresa) que não deve ser tocada por um polish de motion. `TiltDepth` nos botões de submit — rejeitado: mantém o "commit trio" (Lançamento/Assinatura/Cliente) como o conjunto deliberadamente curto de usos, ações de sessão/conta são categoria diferente. Único fix real do lote: `NovaSenhaScreen` usava `labelText:` (label flutuante do Material) em vez de `CampoRotulado` — mesma violação do `AnotarScreen` no Lote 2, corrigida. |

Para cada tela dentro de um lote, o processo é sempre o mesmo:
1. `critique`/`audit` (Impeccable) contra `DESIGN.md` → lista de inconsistências (cor fora de `AppColors`, espaçamento fora do ritmo, estado de erro/vazio/loading ausente).
2. Corrigir o que foi encontrado.
3. `find-animation-opportunities` (Emil Kowalski) → decide **se** essa tela ganha motion novo e onde.
4. Implementar usando `AppMotion`/`TiltDepth` quando fizer sentido.
5. `review-animations` → valida duração, easing e propósito antes de marcar a tela como concluída.

## Decisões técnicas e alternativas consideradas

- **`Transform`/`Matrix4` em vez de pacote de 3D** (ex. `flutter_3d_obj`, `model_viewer_plus`): o app não precisa de modelos 3D reais, só de profundidade percebida em UI 2D (o que o Emil Kowalski descreve como "3D" em contexto de design de interface — tilt, parallax, perspective — não render 3D de verdade). `Matrix4` nativo cobre isso sem dependência nova.
- **Constantes de motion centralizadas (`AppMotion`) em vez de duração/curva inline por tela**: evita repetir o mesmo problema que motivou as extrações recentes de duplicação (`RotuloCard`, `formatarData`) — sem isso, cada tela reintroduziria seu próprio "estilo" de animação e a identidade visual ficaria fragmentada de novo, só que em motion em vez de cor.
- **`TiltDepth` como widget único e opt-in, não um wrapper automático em `AppCard`**: aplicar tilt em todo `AppCard` do app tornaria estático virar "tremido" em conteúdo que não é interativo (ex. cards de resumo só-leitura da Home). Manter opt-in respeita o requisito de "propósito, não decoração".
- **Lotes por área em vez de um PR único**: 20 telas em uma tarefa monolítica não caberia numa sessão e dificultaria revisão; lotes por área alinham com a estrutura de pastas já existente (`lib/empresa`, `lib/lancamentos`, etc.) e permitem parar entre lotes sem deixar nada pela metade.
- **Auth/onboarding por último (Lote 6)**: são as telas mais simples visualmente e onde motion excessivo mais atrapalha (usuário quer entrar rápido) — menor risco, então ficam ao final, quando o vocabulário de motion já estiver validado nos lotes anteriores.

## Riscos / dependências

- **OneDrive trava pastas de build efêmeras do Flutter** (já documentado em `CLAUDE.md`) — rodar `taskkill //F //IM dart.exe` + limpar `ios/Flutter/ephemeral build/flutter_assets build/unit_test_assets` antes de cada `flutter analyze`/`test`/`run` deste spec, em cada lote.
- **Jank em web com `Transform` mal aplicado**: `TiltDepth` deve responder só a hover/press pontual, nunca animação contínua/looping — testar percepção de performance no navegador a cada lote, não só no fim.
- **Escopo grande demais pra uma sessão só**: aceito e endereçado pelos lotes — `tasks.md` reflete isso e cada lote pode ser marcado `[x]` independentemente, retomando em sessões futuras sem perder o fio.
- **Risco de regressão funcional ao mexer em tela que já tem lógica de negócio (ex. `DetalhesLancamentoScreen`)**: diffs desse spec devem tocar só estilo/animação — qualquer mudança de comportamento (ex. lógica de pagamento) fica fora e é tratada como bug separado, não como parte deste polimento.
