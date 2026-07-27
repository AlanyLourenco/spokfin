# Design — Nova Paleta e Tipografia Inter

## Modelagem de dados

Nenhuma. Mudança puramente visual.

## Backend

Nenhum.

## Telas / UI

### Nova paleta (`lib/theme.dart`)

```dart
class AppColors {
  static const background = Color(0xFF0F172A);   // era #090D14
  static const surface = Color(0xFF192134);       // era #111822
  static const surfaceAlt = Color(0xFF232B3E);    // era #1E2732
  static const hairline = Color(0x14FFFFFF);      // era 5% alpha, agora 8%

  static const primary = Color(0xFF1E40AF);        // NOVO — ação de UI
  static const primaryStrong = Color(0xFF1E3A8A);  // NOVO
  static const accent = Color(0xFF059669);          // era #3ED195 (mint) — agora só dinheiro
  static const accentStrong = Color(0xFF047857);    // era #2E9F76
  static const negative = Color(0xFFDC2626);        // era #FB7185 (coral)

  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF94A3B8);       // era #64748B
}
```

`buildAppTheme()`: `colorScheme.primary`/`secondary`, `filledButtonTheme`, `switchTheme`, `segmentedButtonTheme` migrados de `AppColors.accent` pra `AppColors.primary` — isso recolore automaticamente todo `FilledButton`/`Switch`/`SegmentedButton` que usa o estilo padrão do tema, sem precisar tocar a maioria das telas.

### Fonte Inter (`web/index.html` + `theme.dart`)

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;900&display=swap" rel="stylesheet">
```

`ThemeData.textTheme` aplica `fontFamily: 'Inter'` via `.apply()`. Sem pacote novo — carregamento via CSS, mecanismo válido só pra web (o app é web-first; nativo cai pra fonte padrão da plataforma).

### Regra de mapeamento cor-por-uso (aplicada telas por tela)

Toda referência antiga a `AppColors.accent` foi auditada individualmente contra esta regra:

| Uso | Cor nova |
|---|---|
| Valor monetário positivo, saldo positivo, faturamento | `accent` (verde) — mantido |
| Status "Pago" / "Sem Pendências" / débito zerado | `accent` (verde) — mantido |
| Débito, saída de dinheiro, erro, exclusão | `negative` (vermelho) — mantido, só a cor exata mudou |
| Botão de ação (Salvar, Novo, FAB, Falar) | `primary` (azul) — migrado |
| Navegação selecionada (nav bar, segmented button, chip, dropdown) | `primary` (azul) — migrado |
| Avatar (iniciais), link de navegação ("Ver tudo") | `primary` (azul) — migrado |
| Badge de "ação pendente" (ex. NFC-e agendada) | `primary` (azul) — migrado (não é dinheiro) |

20 arquivos revisados: `theme.dart`, `main_shell.dart`, `quick_actions_speed_dial.dart`, `home_screen.dart`, `balanco_screen.dart`, `historico_screen.dart`, `mrr_screen.dart`, `ficha_assinante_screen.dart`, `nova_assinatura_screen.dart`, `clientes_screen.dart`, `cliente_form_screen.dart`, `ficha_cliente_screen.dart`, `ficha_fornecedor_screen.dart`, `revisar_lancamento_screen.dart`, `detalhes_lancamento_screen.dart`, `recibo_dialog.dart`, `falar_screen.dart`, `waveform.dart`, `signup_screen.dart`, `perfil_screen.dart`.

### `DESIGN.md`

Reescrito por completo: nova paleta documentada com os dois papéis semânticos nomeados (`The Two Roles Rule`), tipografia Inter, paleta categórica de gráfico preservada (não mudou).

## Decisões técnicas e alternativas consideradas

- **Fonte via CSS/Google Fonts em vez do pacote `google_fonts`**: o app é web-first (CLAUDE.md) e carregar via `<link>` no `index.html` não introduz nenhuma dependência no `pubspec.yaml`, consistente com a convenção de "sem dependência por reflexo" do projeto. Custo: nativo (Android/iOS, não-alvo principal) não ganha a fonte.
- **Separar `primary` (ação) de `accent` (dinheiro) em vez de só trocar o valor do accent único**: a paleta sugerida pela skill já vem com essa separação (Primary azul + Accent verde), e ela resolve uma ambiguidade real que já existia implicitamente no app (o mint-verde antigo servia tanto pra "botão de ação" quanto "valor positivo" ao mesmo tempo — agora são coisas visualmente diferentes, o que é mais correto pra um app financeiro: o usuário não deveria confundir "isso é um botão" com "isso é R$").
- **Migração centralizada via tema + auditoria manual por arquivo, não busca-e-substitui cega**: `buildAppTheme()` resolve a maioria dos casos (todo `FilledButton`/`Switch`/`SegmentedButton` sem override); os ~40 usos diretos de `AppColors.accent` restantes foram revisados um a um pra decidir se era dinheiro (mantém verde) ou ação (vira azul) — uma troca cega teria deixado valores monetários errados em azul ou botões errados em verde.
- **Achado durante a migração**: um `CircularProgressIndicator` no botão "Salvar" do modo de edição do modal de Detalhes usava `color: AppColors.background` explicitamente — funcionava por acaso quando o botão era verde-claro (bom contraste), mas ficaria quase invisível no novo azul-escuro. Corrigido pra `AppColors.textPrimary`. Também corrigido um `Colors.black` cru (não um token do tema) no botão "Nova" de `MrrScreen`, que já era uma inconsistência antes desta mudança (achada no Lote 4 da spec 0008).

## Riscos / dependências

- **OneDrive**: mesma limitação de ambiente já documentada — `taskkill`/limpar pastas efêmeras antes de cada `flutter analyze`/`test`/`run`.
- **Contraste texto-sobre-botão**: qualquer lugar que ainda tenha `foregroundColor`/`color` hardcoded pra um dos dois tons antigos (mint-claro ou navy-escuro) em vez de `AppColors.textPrimary`/`AppColors.primary` pode ter ficado com contraste ruim — auditoria completa foi feita via grep em todo `lib/`, mas uma checagem visual adicional em telas menos usadas (ex. `NovaSenhaScreen`, só acessível por link de recuperação de senha) fica pendente pra quando o usuário testar.
