# spokfinRM

App Flutter + Supabase de gestão financeira para MEIs. Web-first (roda como app Flutter web), com toolchain Android/iOS já preparado mas não é o alvo principal.

## Workflow obrigatório: Spec-Driven Development (SDD)

**A partir de agora, todo pedido de trabalho passa pelo fluxo de SDD descrito em [`specs/README.md`](specs/README.md) antes de qualquer código ser escrito.** Isso é decisão explícita do usuário e vale para tudo que ele pedir daqui pra frente, não só "features grandes".

1. Criar `specs/NNNN-nome-curto/` (copiar de `specs/_template/`), `NNNN` sendo o próximo número sequencial (ver índice em `specs/README.md`).
2. Escrever `requirements.md` (contexto, objetivo, requisitos funcionais, fora de escopo) — confirmar com o usuário antes de seguir para o design.
3. Escrever `design.md` (modelagem de dados, backend, telas, decisões técnicas) — confirmar antes de implementar.
4. Escrever `tasks.md` (checklist pequeno o bastante pra concluir numa sessão).
5. Implementar seguindo o `tasks.md`, marcando `- [x]` conforme cada item termina.
6. Atualizar o índice de specs em `specs/README.md` (linha da tabela com status).
7. Specs são vivas: se a implementação exigir mudar o design, atualizar o `design.md` antes de continuar.

Exceção de bom senso: correções triviais de uma linha (typo, ajuste de cor, string) não precisam de pasta de spec própria — mas qualquer coisa que mude comportamento, tela ou schema, sim.

Sempre que um `requirements.md`, `design.md` ou `tasks.md` for criado ou atualizado, mostrar o conteúdo completo do arquivo na resposta (não só resumir) — o usuário quer ler e aprovar antes de seguir pra próxima etapa.

## Stack

- **Flutter/Dart** — codebase único, `sdk: ^3.12.2`.
- **Supabase** (Postgres + Auth + Storage + Edge Functions) — backend. Cliente `supabase_flutter`, multi-tenancy baseado em RLS.
- **Edge Functions Deno/TS** em `supabase/functions/`: `parse-lancamento` (extração estruturada do lançamento a partir de texto livre), `transcrever-audio` (áudio → texto) e `excluir-conta` (LGPD, spec 0005). Detalhes de secrets/deploy em [`supabase/functions/README.md`](supabase/functions/README.md).
- **IA: Google Gemini** (`gemini-flash-lite-latest`, camada gratuita) desde a spec 0006 — **não é mais OpenAI**. A `GEMINI_API_KEY` vive só como secret das Edge Functions, nunca chega ao Flutter. Rate limit compartilhado em `supabase/functions/_shared/rate_limit.ts` (30 chamadas/hora por usuário, via RPC `registrar_uso_ia`).
- **Fontes** carregadas via Google Fonts no `web/index.html` (web-only, não empacotadas para nativo): **Inter** para corpo/dado/formulário e **Calistoga** só para título de tela.
- Sem pacote de gerenciamento de estado (nada de Provider/Riverpod/Bloc) — `StatefulWidget` + `setState` puro, com um `ValueNotifier` leve como barramento de atualização entre abas (ver abaixo).
- Sem pacotes de gráficos/máscara/mock — tudo feito à mão (ver Convenções).

## Arquitetura

- `lib/main.dart` — carrega o `.env` via `flutter_dotenv`, inicializa o Supabase, expõe o cliente global `supabase`.
- `lib/auth/auth_gate.dart` — roteamento raiz: `AuthGate` observa `supabase.auth.onAuthStateChange` → `LoginScreen` (deslogado) → fluxo de recuperação de senha → `_EmpresaGate`, que verifica se já existe uma linha em `empresas` para o usuário → `EmpresaSetupScreen` (onboarding) ou `MainShell`.
- `lib/shell/main_shell.dart` — `MainShell` contém as 5 abas da navegação inferior (Home, Balanço, MRR, Histórico, Clientes) dentro de um `IndexedStack`, para que o estado de cada aba sobreviva à troca. O FAB `QuickActionsSpeedDial` fica escondido na aba Home (que já tem suas próprias ações principais).
- Pastas por domínio: `lib/empresa/` (home/onboarding), `lib/lancamentos/` (captura/revisão/detalhes de lançamentos, parsing por IA, áudio), `lib/historico/`, `lib/balanco/` (dashboard mensal), `lib/mrr/` (assinaturas recorrentes), `lib/clientes/` (clientes **e** fornecedores — ver abaixo), `lib/perfil/` (dados da empresa, termos, exclusão de conta), `lib/shared/` (widgets/utilitários transversais).
- `lib/lancamentos/` também guarda o que é transversal ao **conceito** de lançamento, e não a uma tela: o modelo (`lancamento_detalhado.dart`), a leitura (`lancamentos_repository.dart`), a tradução de status (`status_lancamento.dart`) e o tile de lista (`lancamento_tile.dart`). Home, Balanço, Histórico e Ficha do Cliente são consumidores desses arquivos.
- `lib/shared/lancamentos_bus.dart` — mecanismo de atualização entre abas: um `ValueNotifier<int> lancamentosAtualizados` incrementado por `notificarLancamentosAtualizados()` depois de qualquer escrita. Cada tela de aba (sempre viva no `IndexedStack`) adiciona um listener no `initState`/remove no `dispose` que dispara seu próprio `_recarregar()`. Use isso em vez de introduzir uma lib de estado quando uma aba precisar reagir a um lançamento criado/editado em outro lugar.
- Fornecedores **não** são uma tabela separada — são linhas de `clientes` com `tipo = 'fornecedor'` (vs `'cliente'`), reaproveitando o FK `cliente_id` existente em todo lugar (`transacoes`, `contas_pagar_receber`, `assinaturas`). Fornecedores também carregam `chave_pix`/`tipo_chave_pix`. `ClienteFormScreen`, `ClientesScreen`, `FichaClienteScreen`/`FichaFornecedorScreen` todos ramificam nesse discriminador.
- `lib/shared/formatters.dart` concentra **toda** formatação/normalização de texto do app. Antes de escrever um `padLeft`/`toStringAsFixed`/`split` de data ou nome numa tela, use o que já existe aqui:
  - `formatarMoeda` (R$, agrupamento pt-BR — maioria das telas) **e** `formatarValorCifrao` (estilo `$ 1,250.00` — Home, modal de lançamento, Histórico, Balanço, conforme specs de design que usavam literalmente "$"). São dois formatadores em paralelo, de propósito; não confundir os dois.
  - `formatarData` (`dd/mm/aaaa`), `formatarDataCurta` (`dd/mm`, rótulo de gráfico) e `formatarDataIso` (`aaaa-mm-dd`, o formato que as colunas de data do Supabase esperam em query/RPC).
  - `iniciaisDoNome` (avatares) e `normalizarNome` (comparação tolerante a acento/espaço/caixa, usada pra casar o nome que a IA extraiu com o cadastro existente).
- A UI unificada de Detalhes/Edição de lançamento é `lib/lancamentos/detalhes_lancamento_screen.dart`, exibida via `showGeneralDialog` + blur `BackdropFilter`. Precisa continuar envolta em `Material(type: MaterialType.transparency)` (corrige um crash real de "No Material widget found") e as ações de mudança de status (marcar pago/pendente) devem atualizar o estado no local usando a linha retornada pela RPC, em vez de fechar o modal.

## Convenções

- **Sem novas dependências sem um bom motivo.** Gráficos (`_EntradasSaidasChart`, `_DonutChart`/`_DonutPainter` em `balanco_screen.dart`), encoding WAV (`lib/lancamentos/wav_encoder.dart`) e máscaras/validação de input (`lib/shared/mascaras.dart`) são todos feitos à mão em vez de puxar um pacote.
- **Widgets compartilhados antes de widget novo.** `lib/shared/` já tem os blocos visuais recorrentes; código novo compõe a partir deles em vez de remontar o mesmo `Container`/`BoxDecoration` na tela:
  - `AppCard` (`app_card.dart`) — o card padrão (surface + raio 18 + borda hairline). Não escreva um `Container` com `AppColors.surface` + `BorderRadius` à mão.
  - `RotuloCard` (`app_card.dart`) — rótulo pequeno de seção dentro de um card ("CATEGORIA", "FATURAMENTO").
  - `CampoRotulado` (`campo_rotulado.dart`) — rótulo acima do input (ver abaixo).
- **Lançamento tem um modelo, uma carga e um tile** (spec 0010). Tela nova que liste lançamento **não** cria modelo nem consulta própria:
  - `LancamentoDetalhado` (`lib/lancamentos/lancamento_detalhado.dart`) é o único modelo de linha de lançamento — construa pelas factories `deTransacao`/`deConta`, nunca campo a campo a partir de uma linha do Supabase.
  - `lib/lancamentos/lancamentos_repository.dart` é a única leitura: `buscarLancamentos` (parâmetros para período, cliente, limite por fonte, incluir pagos/cancelados), `buscarPaginaLancamentos` (paginação do Histórico) e `buscarVencendoEmBreve`. Lê sempre a view `contas_pagar_receber_vw`, nunca a tabela crua. Agregado de tela (saldo, débito, totais do Balanço) continua na tela.
  - `LancamentoTile`/`PilulaNotaFiscal` (`lib/lancamentos/lancamento_tile.dart`) desenham a linha; o subtítulo vem pronto de quem chama.
  - `lib/lancamentos/status_lancamento.dart` traduz status: `rotuloStatus` (`Pago`/`Pendente`/`Atrasado`), `corStatus`, `iconeStatus`/`corIconeStatus`. Nunca reescreva o ternário de `'atrasado'` numa tela.
- **Motion**: toda duração e curva de animação sai de `AppMotion` (`lib/shared/motion.dart`) — `rapido`/`base`/`lento` e as curvas `entrada`/`saida`. Nunca escreva um `Duration(milliseconds: ...)` ou `Curves.easeInOut` solto numa tela. `TiltDepth` (`lib/shared/tilt_depth.dart`) dá profundidade 3D e é de uso restrito a elementos com afordance real de interação — nunca em texto estático ou em todos os cards de uma tela. Respeite `MediaQuery.disableAnimations` em efeito puramente decorativo. Racional completo em `specs/0008-unificacao-visual-motion/design.md`.
- **Campos de formulário**: envolva todo campo em `CampoRotulado` de `lib/shared/campo_rotulado.dart` (rótulo acima do input via `Column`, não `labelText:`) com `SizedBox(height: 16)` entre grupos de campos. Não use o padrão de label flutuante do Material — ele sobrepõe/corta contra os inputs escuros preenchidos deste app.
- **Máscaras e validação**: `lib/shared/mascaras.dart` tem `TelefoneInputFormatter`, `CpfCnpjInputFormatter` (ambos `TextInputFormatter`s que reformatam a cada tecla) e os validadores `telefoneValido`, `emailValido`, `cpfValido`, `cnpjValido` (dígitos verificadores reais, mod 11) e `cpfCnpjValido` (escolhe pelo tamanho). Reaproveite em vez de refazer regex/checksum em cada tela.
- **Estilo de dropdown** (tema escuro): `dropdownColor: AppColors.surfaceAlt`, `borderRadius: BorderRadius.circular(12)`, e cor manual em cada `Text` de `DropdownMenuItem` — `AppColors.accent` + negrito quando é o valor selecionado, `AppColors.textPrimary` nos demais (o Flutter não estiliza sozinho o item selecionado).
- **Cores/tema**: `lib/theme.dart`'s `AppColors` é a paleta única — **"Trust Ledger"** (spec 0009), azul-marinho quase preto `#0F172A` sobre superfícies em camadas tonais. A regra central é a **separação semântica dos dois acentos**, e ela não é negociável em código novo:
  - `AppColors.primary` / `primaryStrong` (azul-confiança `#1E40AF`) = **ação e UI** — botão, aba selecionada, foco, seleção, chip de estado de UI. Não tem relação com dinheiro.
  - `AppColors.accent` / `accentStrong` (verde-lucro `#059669`) = **dinheiro positivo e status "pago"**, e nada mais. Nunca use verde como cor de ação genérica.
  - `AppColors.negative` (`#DC2626`) = saída de dinheiro e erro. Nunca decorativo.
  - `AppColors.hairline` (branco a 8%) para bordas sutis de card/lista, nunca uma cor de borda sólida.
  - O documento canônico da identidade visual (tokens, motion, anti-padrões) é [`DESIGN.md`](DESIGN.md) — atualize-o junto quando mudar um token.
- **Sem `Form`/`GlobalKey<FormState>` na maioria das telas leves** (bottom sheets, fluxos rápidos) — validação é manual: checar no handler de salvar, dar `setState` numa string `_error`, exibir como texto vermelho acima do botão de envio. Telas que já usam `Form` (telas de auth, `ClienteFormScreen`) continuam usando; não introduza isso nas telas de validação manual sem motivo.
- **Todo módulo de lógica pura ganha um `test/*_test.dart`** (ex.: `formatters_test.dart`, `wav_encoder_test.dart`, `mascaras_test.dart`). `flutter analyze` precisa reportar "No issues found!" e `flutter test` precisa passar antes de commitar.
- Identificadores em português no código inteiro (`_salvar`, `_carregarContatos`, `rotulo`, etc.) — siga esse padrão, não troque para inglês no meio de um arquivo.

## Banco de dados

- Migrations são arquivos `.sql` numerados sequencialmente em `supabase/migrations/`, aplicados **manualmente** pelo usuário via SQL Editor do Supabase (não há runner de migration automatizado nesse fluxo) — depois de adicionar uma, avise ao usuário quais arquivos ainda precisam ser rodados **e atualize a tabela de status em [`supabase/migrations/README.md`](supabase/migrations/README.md)**, que é o único lugar que registra o que já foi aplicado no Supabase de produção.
- Multi-tenancy via RLS usando o padrão de helpers `is_member`/`is_owner` — toda tabela é isolada por um `empresa_id` ao qual o usuário pertence.
- RPCs relevantes: `registrar_pagamento` / `marcar_lancamento_pendente` (migrations 0002/0007, corrigidas na 0011 para carregar `categoria` na transição pago↔pendente) — ambas fazem `returns` da linha atualizada, para que quem chama possa atualizar o estado local sem recarregar tudo.

## Fluxo de desenvolvimento (Windows + OneDrive)

O diretório do projeto fica dentro do OneDrive, que intermitentemente trava as pastas de build efêmeras do Flutter no meio de um build. Antes de **todo** `flutter analyze`/`flutter test`/`flutter run`, rode:

```bash
taskkill //F //IM dart.exe
rm -rf ios/Flutter/ephemeral build/flutter_assets build/unit_test_assets
```

Rode o app web com:

```bash
flutter run -d web-server --web-port=5000 --web-hostname=localhost
```

(`-d chrome` falha de forma consistente ao estabelecer a conexão com o debug service nesse ambiente — não usar.)

### Se o app subir mas o login falhar

Antes de investigar o código, **verifique se o projeto Supabase não está pausado** — o plano gratuito suspende o projeto depois de um período sem uso, e nesse estado não há Auth, banco nem Edge Functions (os dados continuam íntegros; é só clicar em *Resume project* no dashboard). Foi o que aconteceu em 01/09/2026. Detalhes e o que decidir sobre isso: [`specs/requisitos-e-cronograma.md`](specs/requisitos-e-cronograma.md#estado-do-supabase-01092026).

## CI / Repositório

- GitHub: `https://github.com/AlanyLourenco/spokfin` (público, usado no portfólio).
- `.github/workflows/ci.yml` roda `flutter analyze` + `flutter test` a cada push/PR na `main`. Ele copia `.env.example` → `.env` antes, já que analyze/test nunca chamam `Supabase.initialize()` mas o asset está declarado no `pubspec.yaml`.
- Sentry: propositalmente não configurado ainda (usuário não tem conta) — não adicionar sem ser pedido.

## Documentação do projeto

Cada documento tem **um** dono de assunto. Ao mudar algo, atualize o documento canônico daquele assunto — não duplique a informação em outro lugar.

| Documento | É a fonte da verdade sobre |
|---|---|
| `README.md` | Apresentação pública do projeto (problema, solução, stack, como rodar). |
| `CLAUDE.md` (este) | Como trabalhar no código: arquitetura, convenções, fluxo de dev. |
| `PRODUCT.md` | Quem é o usuário, o que o produto se propõe a ser, princípios de produto. |
| `DESIGN.md` | Identidade visual: tokens de cor/tipografia/espaçamento, motion, anti-padrões. |
| `supabase/migrations/README.md` | Estado do banco: o que cada migration faz, **o que já foi aplicado**, mapa de tabelas/views/RPCs. |
| `supabase/functions/README.md` | Edge Functions: o que cada uma faz, secrets, como implantar. |
| `specs/README.md` | Índice das specs + o fluxo de SDD. |
| `specs/historias-de-usuario.md` | Comportamento esperado de cada tela, como histórias de usuário. |
| `specs/requisitos-e-cronograma.md` | Roadmap: inventário do que existe/falta e ordem de execução (Fases A-F). |
| `specs/NNNN-*/` | Uma feature: `requirements.md` → `design.md` → `tasks.md`. `specs/_template/` mostra o formato. |

**Ao concluir uma feature**, atualize nesta ordem: `tasks.md` (marcar itens) → linha da tabela em `specs/README.md` → item correspondente em `specs/requisitos-e-cronograma.md` → `supabase/migrations/README.md` se houve migration.
