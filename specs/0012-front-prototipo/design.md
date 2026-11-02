# Design — Alinhar o front ao protótipo (spokfin-ledger-ai)

## Modelagem de dados

Nenhuma. Sem migration, sem alteração de tabela, view, RPC ou Edge Function. Nenhuma consulta ao Supabase muda.

## Backend

Nenhum.

## Tokens (`lib/theme.dart`)

A paleta do protótipo entra inteira, menos a cor de ação (decisão 1 do `requirements.md`). Os hex do protótipo saíram do CSS dele, não de conta-gotas em screenshot.

| Token | Hoje | Novo | Origem |
|---|---|---|---|
| `background` | `#0F172A` | **`#04090D`** | `--background` do protótipo |
| `surface` | `#192134` | **`#0D1520`** | `--surface` |
| `surfaceSunken` *(novo)* | — | **`#0A1119`** | `--surface-2` |
| `surfaceAlt` | `#232B3E` | **removido** | ver §Decisão D2 |
| `border` | `#232B3E` | **`#1B2533`** | `--border-subtle` |
| `hairline` | `#14FFFFFF` | mantido | separador de linha de lista |
| `primary` | `#1E40AF` | **`#2563EB`** | ver §Decisão D1 |
| `primaryStrong` | `#1E3A8A` | **`#1D4ED8`** | idem |
| `accent` | `#059669` | **`#4ADE80`** | `--mint` — a cor de dinheiro do protótipo |
| `accentStrong` | `#047857` | **`#22C55E`** | derivado |
| `negative` | `#DC2626` | **`#FB7185`** | `--coral` |
| `textPrimary` | `#FFFFFF` | **`#F5F7FA`** | `--foreground` |
| `textMuted` | `#94A3B8` | **`#6B7A8F`** | `--muted-fg` |

Tipografia: **Inter em tudo**. A Calistoga sai do `titleTextStyle` do `AppBar` e do wordmark "spokfin" — o protótipo usa uma sans só (ver §Decisão D3).

## Estrutura

### 1. Coluna centralizada — `lib/shared/coluna_central.dart` (novo)

O protótipo é uma coluna de ~390px. Hoje o app estica pela largura toda: numa tela de 1366px, a linha de lançamento fica com um vão enorme entre descrição e valor.

```dart
class ColunaCentral extends StatelessWidget {
  const ColunaCentral({super.key, required this.child, this.larguraMaxima = 460});
  ...
  // Align(topCenter) + ConstrainedBox(maxWidth) — não centraliza verticalmente,
  // senão tela curta ficaria flutuando no meio.
}
```

Aplicado **uma vez**, no `builder:` do `MaterialApp` em `main.dart`:

```dart
builder: (context, child) => ColunaCentral(child: child!),
```

Isso cobre as 20+ telas de uma vez, incluindo as que forem criadas depois, sem tocar em `Scaffold` nenhum. É a diferença entre uma linha e vinte edições — e impossível de esquecer numa tela nova.

### 2. Navegação flutuante — `lib/shell/navegacao_flutuante.dart` (novo)

Substitui o `NavigationBar` do Material dentro de `MainShell`. Pílula arredondada sobre o conteúdo:

- contêiner: `surface`, borda `border`, raio total (999), margem inferior de 12 e horizontal de 16, sombra suave;
- 5 itens em `Row`, cada um ícone (20) + rótulo (10);
- item ativo: retângulo preenchido de `primary`, raio 14, ícone e rótulo em `textPrimary`;
- inativo: ícone e rótulo em `textMuted`;
- transição do indicador com `AppMotion.rapido`/`AppMotion.entrada` — a barra do Material já animava, e perder isso seria regressão.

`MainShell` passa a usar `extendBody: true` para o conteúdo correr por baixo da pílula, e cada tela ganha o respiro inferior correspondente.

### 3. FAB

`QuickActionsSpeedDial` mantém o comportamento (é o speed dial da spec `0008`, com stagger e `TiltDepth`); muda só a aparência: círculo `primary` acima da navegação. Nada da lógica de expansão é tocado.

### 4. `AppCard` e `RotuloCard`

`AppCard` troca a borda de `hairline` para a `border` sólida `#1B2533` e o raio de 18 para 16. A assinatura não muda, então as ~40 telas que já usam `AppCard` herdam o visual novo sem edição.

`RotuloCard` mantém tamanho 11 e passa a usar `textMuted` novo — os rótulos "SALDO ATUAL"/"FATURAMENTO" do protótipo têm o mesmo tratamento em caixa alta com espaçamento.

### 5. Cabeçalho de tela secundária

O `AppBarTheme` já centraliza isso. Muda: fonte (Inter), fundo `background`, e o padrão do protótipo de uma pílula de ação à direita — que é o `actions:` que as telas já usam ("Novo", "Nova", "Editar"). Nenhuma tela precisa mudar de estrutura; só herdam o tema.

### 6. `LancamentoTile`

Herda os tokens novos automaticamente. Único ajuste próprio: o valor passa de `+ $ 300.00` para `+$ 300.00` (sem espaço entre sinal e cifrão), como o protótipo — o que muda `formatarValorCifrao` ou a composição no tile. **Fica em `lancamento_tile.dart`**, não numa cópia por tela: a spec `0010` acabou de eliminar essas cópias.

## Etapas de execução

- **Etapa 1 — fundação.** Tokens, `AppCard`, `ColunaCentral`, navegação flutuante, FAB. Sem tocar em tela: o ganho vem por herança, e já é o que mais se sente. Fecha com analyze/test verdes e conferência no navegador.
- **Etapa 2 — as 5 telas principais.** Home, Balanço, MRR, Histórico, Clientes, comparadas uma a uma com o protótipo.
- **Etapa 3 — as telas secundárias.** Login, cadastro, recuperação, onboarding, Anotar, Falar, Revisar, Detalhes, Fichas, Nova Assinatura, Perfil, Termos, Recibo — que o protótipo não desenhou e precisam receber a linguagem por extensão.

## Decisões técnicas e alternativas consideradas

- **D1 — o azul de ação clareia de `#1E40AF` para `#2563EB`.** A decisão do usuário foi manter o azul como cor de ação, não manter o *tom*. Sobre o fundo quase preto do protótipo, o `#1E40AF` fica pesado e apagado ao lado do mint; o `#2563EB` (blue-600) tem a mesma energia visual dos botões mint do protótipo e continua inequivocamente azul. Preserva a regra da spec `0009` e a vivacidade do protótipo ao mesmo tempo.
- **D2 — `surfaceAlt` é removido, e o campo de formulário passa a usar `surface`.** No protótipo, `--surface-2` (`#0A1119`) é *mais escuro* que `--surface`; hoje o nosso `surfaceAlt` é *mais claro* que `surface` e serve de preenchimento de input, dropdown e avatar. Copiar o protótipo literalmente deixaria um campo de formulário a `#0A1119` sobre um fundo `#04090D` — praticamente invisível, já que a maioria dos formulários do app não está dentro de card. Então: campo de formulário usa `surface` (`#0D1520`, um degrau visível sobre o fundo) e o `#0A1119` entra como `surfaceSunken`, para área rebaixada **dentro** de card (fundo de gráfico, mini-stat). Trocar o nome obriga a revisitar cada uso, o que é justamente o que se quer aqui.
- **D3 — a Calistoga sai.** O protótipo usa uma sans só, e a decisão foi adotá-lo salvo na cor de ação. A Calistoga entrou na spec `0008` para dar personalidade de marca no título de tela; abrir mão dela é o custo de ficar fiel. É reversível em uma linha (`titleTextStyle` no `theme.dart`), e a fonte continua carregada no `web/index.html` — se você olhar e achar que perdeu personalidade, volta.
- **D4 — o coral substitui o vermelho também em erro.** `AppColors.negative` serve hoje a dois papéis: saída de dinheiro e mensagem de erro. O protótipo só tem o coral. Manter um token só evita inventar um vermelho que o protótipo não tem; o coral é legível como erro sobre o fundo quase preto.
- **D5 — a coluna centralizada entra pelo `builder:` do `MaterialApp`, não tela a tela.** Uma linha cobre tudo, inclusive tela futura. A alternativa (envolver cada `Scaffold`) seria 20 edições que a próxima tela esqueceria.
- **D6 — a navegação vira widget próprio em vez de `NavigationBar` estilizado.** O `NavigationBar` do Material 3 não faz pílula flutuante com indicador retangular preenchido sem briga com o `indicatorShape`/`height`/`labelBehavior`. Um `Row` de 5 itens é menos código do que dobrar o componente do Material — e o projeto já desenha gráfico e máscara à mão por esse mesmo critério.

## Riscos / dependências

- **Risco: contraste.** Fundo quase preto com texto `#6B7A8F` é um par de baixo contraste (≈4.6:1 sobre `#04090D`) — passa em texto normal, fica no limite em texto pequeno. Os rótulos de 10-11px da navegação e do `RotuloCard` são o ponto de atenção; se ficarem ilegíveis, a saída é clarear o `textMuted` em vez de aumentar a fonte.
- **Risco: as telas secundárias ficarem para trás.** São 15 telas que o protótipo não desenhou. Herdar tokens resolve cor, mas não estrutura — a Etapa 3 existe para isso e não pode ser cortada, senão o app fica com duas caras.
- **Dependência: conferir contra dado real.** Vários estados (atrasado, cancelado, NFC-e, "Carregar mais") não existem na base atual, como o teste da spec `0010` mostrou. A Etapa 2 vai conferir o que der; o resto depende da spec `0011`.
- **Sem risco de dado**: nenhuma consulta, RPC ou migration é tocada.
