---
name: spokfinRM
description: Gestão financeira para MEIs — dashboard financeiro escuro, azul-confiança + verde-lucro, tipografia Inter
colors:
  midnight-navy: "#0F172A"
  deep-surface: "#192134"
  surface-alt: "#232B3E"
  hairline: "rgba(255,255,255,0.08)"
  trust-blue: "#1E40AF"
  trust-blue-strong: "#1E3A8A"
  profit-green: "#059669"
  profit-green-strong: "#047857"
  alert-red: "#DC2626"
  text-primary: "#FFFFFF"
  text-muted: "#94A3B8"
  chart-blue: "#60A5FA"
  chart-amber: "#FBBF24"
  chart-violet: "#A78BFA"
  chart-teal: "#5EEAD4"
typography:
  title:
    fontFamily: "Calistoga, Georgia, serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: 1.2
  body:
    fontFamily: "Inter, system-ui, Roboto, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Inter, system-ui, Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    letterSpacing: "0.02em"
  rotulo-card:
    fontFamily: "Inter, system-ui, Roboto, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    letterSpacing: "normal"
rounded:
  sm: "12px"
  md: "18px"
  lg: "24px"
  pill: "999px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "16px"
  lg: "20px"
components:
  card:
    backgroundColor: "{colors.deep-surface}"
    rounded: "{rounded.md}"
    padding: "16px"
  button-primary:
    backgroundColor: "{colors.trust-blue}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "14px 20px"
  input-field:
    backgroundColor: "{colors.surface-alt}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
---

# Design System: spokfinRM

## Overview

**Creative North Star: "Trust Ledger"**

spokfinRM é um painel financeiro que vive num azul-marinho quase preto (`#0F172A`), com dois acentos semânticos separados por papel: **azul-confiança** para toda ação/navegação de UI, e **verde-lucro** reservado só para valor monetário positivo e status "pago". Vermelho sinaliza saída de dinheiro e erro. Não há gradientes, ilustrações ou textura; a hierarquia vem de tom de superfície, peso tipográfico (Inter) e a separação estrita entre "isso é uma ação" (azul) e "isso é dinheiro" (verde/vermelho). É um sistema pensado pra alguém que abre o app rapidamente, no meio de um atendimento, pra registrar um lançamento e sair — mas que também precisa distinguir, num piscar de olho, se um número é uma ação clicável ou um valor em reais.

O app rejeita explicitamente qualquer dependência visual de terceiros: gráficos, máscaras de input e o encoder de áudio são todos construídos à mão. A fonte Inter é a única exceção deliberada — carregada via Google Fonts no `web/index.html` (o app é web-first; não empacotamos a fonte para nativo).

**Key Characteristics:**
- Fundo azul-marinho quase preto, superfícies em camadas tonais (nunca sombra) para indicar elevação.
- **Dois acentos com papéis mutuamente exclusivos**: azul-confiança = ação/UI, verde-lucro = dinheiro positivo. Nunca o mesmo elemento usa os dois.
- Vermelho reservado exclusivamente para valores negativos/saída de dinheiro e erro — nunca decorativo.
- Tipografia Inter (pesos 400–900), hierarquia por peso e tamanho.
- Bordas quase invisíveis (`hairline`, branco a 8% de opacidade) em vez de bordas sólidas ou sombras.

## Colors

Paleta escura de navy com dois acentos semânticos estritamente separados por função — nunca decorativos, nunca intercambiáveis.

### Primary
- **Trust Blue** (`#1E40AF`): toda ação de UI — botão preenchido padrão, FAB, indicador de navegação selecionado, foco de switch/slider, chip/dropdown selecionado, avatar (iniciais), link. Não tem relação com valor monetário — é a cor "isso é clicável/selecionado".
- **Trust Blue Strong** (`#1E3A8A`): variante mais escura, usada em trilhos de switch selecionado e estados que precisam de menos contraste que o acento puro.

### Secondary
- **Profit Green** (`#059669`): exclusivamente para valor monetário positivo (entrada, saldo positivo, faturamento) e status "pago"/"sem pendências". Nunca usado em botão de ação genérico ou navegação.
- **Profit Green Strong** (`#047857`): variante mais escura do verde, para estados de menor contraste.

### Tertiary
- **Alert Red** (`#DC2626`): saída de dinheiro, débito, valores negativos, erro e ações destrutivas (excluir). Nunca usado como decoração.

### Neutral
- **Midnight Navy** (`#0F172A`): fundo base de toda a tela (`scaffoldBackgroundColor`), incluindo AppBar (sem elevação, mesma cor do fundo).
- **Deep Surface** (`#192134`): superfície de card (`AppCard`), um degrau acima do fundo.
- **Surface Alt** (`#232B3E`): superfície de input preenchido, dropdown, chip de ação secundária — um degrau acima de `Deep Surface`.
- **Hairline** (`rgba(255,255,255,0.08)`): borda ultra-sutil de card e separador de lista.
- **Text Primary** (`#FFFFFF`): texto principal, valores, títulos — também o texto sobre botões/chips azuis (contraste claro sobre escuro, não mais invertido).
- **Text Muted** (`#94A3B8`): rótulos, texto secundário, placeholder, ícone/label não selecionado na navegação.

### Chart Categorical Palette
- **Chart Blue** (`#60A5FA`), **Chart Amber** (`#FBBF24`), **Chart Violet** (`#A78BFA`), **Chart Teal** (`#5EEAD4`): usadas junto com `Profit Green`/`Alert Red` para diferenciar 3+ categorias no donut/legenda de "Gastos por Categoria" do Balanço — nunca fora de gráfico categórico.

### Named Rules
**The Two Roles Rule.** Azul = ação de UI. Verde = dinheiro positivo. Um mesmo elemento nunca usa os dois — se um botão de ação está verde, ou é o valor monetário sendo exibido (não uma ação), ou é um bug.
**The No Hard Border Rule.** Cards e listas se delimitam com `hairline` (8% de opacidade) ou diferença de tom de superfície — nunca com uma borda sólida de cor neutra forte.

## Typography

**Display Font:** Calistoga (serif expressivo, peso único 400) — só em título de tela (`AppBarTheme.titleTextStyle`) e no wordmark "spokfin" da Home. Dá personalidade de marca onde não há dado numérico.

**Body/Label Font:** Inter (pesos 400/500/600/700/900) — todo o resto: corpo de texto, formulário, e crucialmente todo **valor monetário** (números tabulares de verdade; Calistoga não tem). Ambas carregadas via Google Fonts no `web/index.html`.

**Character:** o par existe deliberadamente pra não ser "uma fonte genérica em toda a tela" — Calistoga carrega a voz de marca nos títulos; Inter carrega precisão técnica em tudo que é dado/formulário/dinheiro. Nenhuma das duas é decorativa fora do papel que exerce.

### Hierarchy
- **Title** (Calistoga, regular/`w400`, ~20px): título de tela (`AppBar`) e o wordmark da Home. Nunca usado em valor numérico.
- **Body** (Inter regular, ~14px): texto corrido, descrição de lançamento, conteúdo de card.
- **Label** (Inter `w500`, ~12px, usado em `CampoRotulado`): rótulo de campo de formulário, acima do input — nunca como label flutuante do Material.
- **Rótulo de card** (Inter regular, 11px, opcional `letterSpacing`/negrito via `RotuloCard`): cabeçalho de seção em caixa alta dentro de um card (ex. "CATEGORIA", "FATURAMENTO").

### Named Rules
**The Label-Above Rule.** Todo campo de formulário tem o rótulo como texto separado acima do input (`CampoRotulado`), nunca como label flutuante do Material.
**The Display-Never-Numeric Rule.** Calistoga nunca aparece em cima de um valor monetário ou dado tabular — só em título de tela e no wordmark. Todo número usa Inter.

## Layout

Mobile-first (mesmo rodando como Flutter web), navegação por abas inferior fixa (`NavigationBar`) com 5 destinos, mais um FAB de ações rápidas (`QuickActionsSpeedDial`) presente em todas as abas exceto Home. Conteúdo por aba fica vivo simultaneamente num `IndexedStack`. Espaçamento entre grupos de campo em formulário é fixo em 16px; dentro de um `CampoRotulado`, 6px entre rótulo e input.

## Elevation & Depth

Sistema estritamente flat com **camadas tonais**, nunca sombra. Profundidade é comunicada só pela progressão de tom: `Midnight Navy` → `Deep Surface` → `Surface Alt`, delimitado por `hairline` em vez de sombra projetada.

### Named Rules
**The Flat-By-Tone Rule.** Elevação nunca usa sombra. Um elemento "acima" de outro é sempre um tom de superfície mais claro, nunca um `boxShadow`.

## Shapes

Cantos consistentemente arredondados: cards em `18px`, botão preenchido em `24px` (quase pílula), input em `14px`, chip/badge/FAB secundário em `999px` (pílula completa). Sem bordas sólidas — delimitação é por `hairline` ou ausência total de borda.

## Components

### Buttons
- **Shape:** pílula quase completa (`borderRadius: 24px`).
- **Primary (`FilledButton`):** fundo `Trust Blue`, texto `Text Primary` (branco), padding `14px` vertical / `20px` horizontal. Todo `FilledButton` sem override explícito herda isso do tema.
- **Destructive:** fundo `Alert Red`, texto `Text Primary` — usado só em confirmação de exclusão.
- **FAB de ação rápida:** fundo `Trust Blue` (ação principal) ou `Surface Alt` (ações secundárias do speed dial).

### Chips / Segmented Buttons
- **Style:** fundo `Surface Alt`, texto `Text Muted` quando não selecionado.
- **Selected:** fundo `Trust Blue`, texto `Text Primary`.

### Status Badges
Dois padrões distintos, por semântica — não intercambiáveis:
- **Ação pendente** (ex. "NFC-e agendada"): pílula com borda sólida em `Trust Blue` e fundo transparente — sinaliza algo que ainda vai acontecer (não é dinheiro).
- **Estado de pagamento** (ex. status de assinatura em `MrrScreen`, "Sem Pendências" em `FichaClienteScreen`): pílula com fundo na cor semântica monetária (`Profit Green`/`Alert Red`) a 15% de opacidade e texto na cor cheia — sinaliza um estado financeiro presente.

### Cards / Containers (`AppCard`)
- **Corner Style:** `18px`.
- **Background:** `Deep Surface`.
- **Shadow Strategy:** nenhuma — ver Elevation & Depth.
- **Border:** `hairline` em todo o perímetro.
- **Internal Padding:** `16px` por padrão, sobrescrevível por instância.

### Inputs / Fields
- **Style:** preenchido, fundo `Surface Alt`, sem borda visível, raio `14px`.
- **Rótulo:** sempre via `CampoRotulado` (texto acima, não label flutuante).
- **Dropdown:** fundo `Surface Alt`, raio `12px`; item selecionado em `Trust Blue` + negrito, demais itens em `Text Primary`.

### Navigation (`NavigationBar`)
- **Style:** fundo `Midnight Navy` (mesma cor do body), indicador de seleção `Trust Blue`.
- **Selected:** ícone e label `Text Primary` (sobre o indicador azul).
- **Unselected:** ícone e label em `Text Muted`.

### Speed Dial (`QuickActionsSpeedDial`)
Componente de assinatura do sistema: FAB principal (`Trust Blue`, com leve profundidade 3D via `TiltDepth`) que expande em até 3 ações (Manual / Anotar / Falar). A ação "Falar" (voz, o mecanismo central do produto) é a única marcada com `destaque: true` → fundo `Trust Blue` também (mesma cor do FAB principal, já que é uma ação de UI, não dinheiro).

## Do's and Don'ts

### Do:
- **Do** usar `hairline` (`rgba(255,255,255,0.08)`) para qualquer borda de card/lista — nunca uma cor de borda sólida.
- **Do** indicar profundidade só por progressão de tom de superfície, nunca por sombra.
- **Do** usar `Trust Blue` para toda ação/navegação/seleção de UI — nunca para exibir um valor monetário.
- **Do** usar `Profit Green` exclusivamente pra valor monetário positivo/status pago — nunca em botão ou navegação.
- **Do** estilizar manualmente o item selecionado de todo `DropdownMenuItem` (`Trust Blue` + negrito) — o Flutter não faz isso sozinho neste tema escuro.

### Don't:
- **Don't** usar o label flutuante padrão do Material em campo de formulário — sempre `CampoRotulado`.
- **Don't** introduzir sombra (`boxShadow`/`elevation` > 0) como recurso de hierarquia.
- **Don't** misturar os papéis de `Trust Blue` e `Profit Green` no mesmo elemento — ação de UI é azul, dinheiro positivo é verde, nunca os dois ao mesmo tempo.
- **Don't** adicionar cor, raio ou espaçamento fora da escala documentada aqui sem atualizar este arquivo primeiro.
