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
- **Edge Functions Deno/TS** em `supabase/functions/` para parsing com IA (`parse-lancamento`) e transcrição de áudio (`transcrever-audio`).
- Sem pacote de gerenciamento de estado (nada de Provider/Riverpod/Bloc) — `StatefulWidget` + `setState` puro, com um `ValueNotifier` leve como barramento de atualização entre abas (ver abaixo).
- Sem pacotes de gráficos/máscara/mock — tudo feito à mão (ver Convenções).

## Arquitetura

- `lib/main.dart` — carrega o `.env` via `flutter_dotenv`, inicializa o Supabase, expõe o cliente global `supabase`.
- `lib/auth/auth_gate.dart` — roteamento raiz: `AuthGate` observa `supabase.auth.onAuthStateChange` → `LoginScreen` (deslogado) → fluxo de recuperação de senha → `_EmpresaGate`, que verifica se já existe uma linha em `empresas` para o usuário → `EmpresaSetupScreen` (onboarding) ou `MainShell`.
- `lib/shell/main_shell.dart` — `MainShell` contém as 5 abas da navegação inferior (Home, Balanço, MRR, Histórico, Clientes) dentro de um `IndexedStack`, para que o estado de cada aba sobreviva à troca. O FAB `QuickActionsSpeedDial` fica escondido na aba Home (que já tem suas próprias ações principais).
- Pastas por domínio: `lib/empresa/` (home/onboarding), `lib/lancamentos/` (captura/revisão/detalhes de lançamentos, parsing por IA, áudio), `lib/historico/`, `lib/balanco/` (dashboard mensal), `lib/mrr/` (assinaturas recorrentes), `lib/clientes/` (clientes **e** fornecedores — ver abaixo), `lib/shared/` (widgets/utilitários transversais).
- `lib/shared/lancamentos_bus.dart` — mecanismo de atualização entre abas: um `ValueNotifier<int> lancamentosAtualizados` incrementado por `notificarLancamentosAtualizados()` depois de qualquer escrita. Cada tela de aba (sempre viva no `IndexedStack`) adiciona um listener no `initState`/remove no `dispose` que dispara seu próprio `_recarregar()`. Use isso em vez de introduzir uma lib de estado quando uma aba precisar reagir a um lançamento criado/editado em outro lugar.
- Fornecedores **não** são uma tabela separada — são linhas de `clientes` com `tipo = 'fornecedor'` (vs `'cliente'`), reaproveitando o FK `cliente_id` existente em todo lugar (`transacoes`, `contas_pagar_receber`, `assinaturas`). Fornecedores também carregam `chave_pix`/`tipo_chave_pix`. `ClienteFormScreen`, `ClientesScreen`, `FichaClienteScreen`/`FichaFornecedorScreen` todos ramificam nesse discriminador.
- Dois formatadores de moeda em paralelo em `lib/shared/formatters.dart`: `formatarMoeda` (R$, agrupamento pt-BR — maioria das telas) e `formatarValorCifrao` (estilo "$" — Home, modal de lançamento, Histórico, Balanço, conforme specs de design que usavam literalmente "$"). Não confundir os dois.
- A UI unificada de Detalhes/Edição de lançamento é `lib/lancamentos/detalhes_lancamento_screen.dart`, exibida via `showGeneralDialog` + blur `BackdropFilter`. Precisa continuar envolta em `Material(type: MaterialType.transparency)` (corrige um crash real de "No Material widget found") e as ações de mudança de status (marcar pago/pendente) devem atualizar o estado no local usando a linha retornada pela RPC, em vez de fechar o modal.

## Convenções

- **Sem novas dependências sem um bom motivo.** Gráficos (`_EntradasSaidasChart`, `_DonutChart`/`_DonutPainter` em `balanco_screen.dart`), encoding WAV (`lib/lancamentos/wav_encoder.dart`) e máscaras/validação de input (`lib/shared/mascaras.dart`) são todos feitos à mão em vez de puxar um pacote.
- **Campos de formulário**: envolva todo campo em `CampoRotulado` de `lib/shared/campo_rotulado.dart` (rótulo acima do input via `Column`, não `labelText:`) com `SizedBox(height: 16)` entre grupos de campos. Não use o padrão de label flutuante do Material — ele sobrepõe/corta contra os inputs escuros preenchidos deste app.
- **Máscaras e validação**: `lib/shared/mascaras.dart` tem `TelefoneInputFormatter`, `CpfCnpjInputFormatter` (ambos `TextInputFormatter`s que reformatam a cada tecla) e os validadores `telefoneValido`, `emailValido`, `cpfValido`, `cnpjValido` (dígitos verificadores reais, mod 11) e `cpfCnpjValido` (escolhe pelo tamanho). Reaproveite em vez de refazer regex/checksum em cada tela.
- **Estilo de dropdown** (tema escuro): `dropdownColor: AppColors.surfaceAlt`, `borderRadius: BorderRadius.circular(12)`, e cor manual em cada `Text` de `DropdownMenuItem` — `AppColors.accent` + negrito quando é o valor selecionado, `AppColors.textPrimary` nos demais (o Flutter não estiliza sozinho o item selecionado).
- **Cores/tema**: `lib/theme.dart`'s `AppColors` é a paleta única ("Cosmic Minimalism" — fundo quase preto, verde-menta de destaque `#3ED195`, coral negativo `#FB7185`). Use `AppColors.hairline` (branco a 5% de opacidade) para bordas sutis de card/lista, não uma cor de borda sólida.
- **Sem `Form`/`GlobalKey<FormState>` na maioria das telas leves** (bottom sheets, fluxos rápidos) — validação é manual: checar no handler de salvar, dar `setState` numa string `_error`, exibir como texto vermelho acima do botão de envio. Telas que já usam `Form` (telas de auth, `ClienteFormScreen`) continuam usando; não introduza isso nas telas de validação manual sem motivo.
- **Todo módulo de lógica pura ganha um `test/*_test.dart`** (ex.: `formatters_test.dart`, `wav_encoder_test.dart`, `mascaras_test.dart`). `flutter analyze` precisa reportar "No issues found!" e `flutter test` precisa passar antes de commitar.
- Identificadores em português no código inteiro (`_salvar`, `_carregarContatos`, `rotulo`, etc.) — siga esse padrão, não troque para inglês no meio de um arquivo.

## Banco de dados

- Migrations são arquivos `.sql` numerados sequencialmente em `supabase/migrations/`, aplicados **manualmente** pelo usuário via SQL Editor do Supabase (não há runner de migration automatizado nesse fluxo) — depois de adicionar uma, avise ao usuário quais arquivos ainda precisam ser rodados.
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

## CI / Repositório

- GitHub: `https://github.com/AlanyLourenco/spokfin` (privado).
- `.github/workflows/ci.yml` roda `flutter analyze` + `flutter test` a cada push/PR na `main`. Ele copia `.env.example` → `.env` antes, já que analyze/test nunca chamam `Supabase.initialize()` mas o asset está declarado no `pubspec.yaml`.
- Sentry: propositalmente não configurado ainda (usuário não tem conta) — não adicionar sem ser pedido.

## Specs

- `specs/historias-de-usuario.md` — histórias de usuário por área da aplicação.
- `specs/requisitos-e-cronograma.md` — roadmap (Fases A/B/C/...).
- `specs/000N-*/` — pastas de spec por feature, `specs/_template` mostra o formato de uma nova.
