# Requisitos — Nova Paleta (Azul + Verde) e Tipografia Inter

## Contexto

Depois da spec [0008](../0008-unificacao-visual-motion/) (motion), o usuário testou o app e não percebeu diferença visual suficiente — o polimento de motion foi deliberadamente sutil (por design, seguindo a filosofia de restrição do Emil Kowalski), mas isso não correspondeu à expectativa de "deixar tudo muito bom" que motivou o pedido original. O usuário pediu explicitamente para usar a skill **UI/UX Pro Max** (instalada nesta sessão, `.claude/skills/ui-ux-pro-max/`) para melhorar cores, paleta, fonte e regras de design do spokfin.

A skill foi rodada (`search.py --design-system "fintech finance dashboard small business dark mode minimal"`) e sugeriu uma paleta "Trust blue + profit green" (azul-confiança como cor primária de ação, verde como cor de lucro) e a fonte Inter (recomendada para fintech/dashboards). Apresentei 3 opções ao usuário (manter o verde-menta só refinando, adotar azul+verde, ou adotar dourado+roxo) e ele escolheu explicitamente **trocar para a paleta azul+verde sugerida**.

## Objetivo

O app usa uma paleta com dois papéis semânticos estritamente separados — azul (`#1E40AF`) para toda ação/navegação de UI, verde (`#059669`) só para valor monetário positivo/status pago — e tipografia Inter em vez da fonte padrão do sistema, com uma diferença visual imediatamente perceptível em qualquer tela do app.

## Requisitos funcionais

- [x] `theme.dart`: `AppColors` reescrito com a nova paleta (`primary` azul, `accent` verde, `negative` vermelho, fundo/superfícies em tom navy) e `ThemeData` atualizado (botões, switch, segmented button, nav) usando `primary` como cor de ação central.
- [x] Fonte Inter carregada via Google Fonts no `web/index.html` (sem pacote novo — app é web-first) e aplicada via `TextTheme` do tema.
- [x] Toda referência a `AppColors.accent`/`AppColors.negative` em cada uma das 20 telas do app foi revisada individualmente: mantida verde/vermelha quando representa valor monetário ou status de pagamento; trocada para `AppColors.primary` (azul) quando representa ação de UI, navegação, seleção ou avatar.
- [x] Nenhuma cor "AppColors.background"/"AppColors.textPrimary" usada como texto sobre um elemento cuja cor de fundo mudou (ex: botões que eram verde-claro e agora são azul-escuro precisam de texto branco, não mais texto escuro) — checado em toda a base.
- [x] `DESIGN.md` reescrito refletindo a nova paleta, os dois papéis semânticos (`Two Roles Rule`) e a tipografia Inter.
- [x] `flutter analyze` limpo e `flutter test` passando.
- [x] Testado visualmente no navegador (Home, Balanço, MRR, Clientes, Login) confirmando a nova paleta aplicada de ponta a ponta sem quebra de contraste.

## Fora de escopo

- Nenhuma dependência nova no `pubspec.yaml` — Inter é carregada só via CSS/Google Fonts no `web/index.html` (mecanismo específico de web, consistente com o app ser web-first).
- Build Android/iOS não recebe a fonte Inter (cairia de volta pra fonte padrão da plataforma) — aceito, não é o alvo principal do app.
- Não foi um redesign de layout/componentes — só recor e retipografia. Estrutura, espaçamento e comportamento de cada tela continuam os mesmos da spec 0008.

## Perguntas em aberto

Nenhuma — decisão de paleta já confirmada explicitamente pelo usuário via pergunta estruturada.
