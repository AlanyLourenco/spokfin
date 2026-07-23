# Design — Conformidade Legal (LGPD)

## Modelagem de dados
- **Migration nova** `0013_empresa_telefone.sql`: `alter table empresas add column telefone text;` — único campo que a tela de Perfil precisa e ainda não existe (todos os outros — razao_social, nome_fantasia, cnpj, cpf — já existem desde 0001/0004).
- **Consentimento (N8)**: não cria tabela nova. Vai como `user_metadata` do próprio `auth.users`, passado no `data:` do `supabase.auth.signUp()` (`{'termos_aceitos_em': <ISO8601 UTC>}`). Isso evita uma tabela só pra guardar um timestamp, e o registro morre automaticamente junto com o usuário quando a conta é excluída (N7) — não sobra um registro "órfão" de consentimento depois que os dados que ele protegia já foram apagados.
- **Nenhuma tabela nova pra N7** — ver Backend abaixo: a cascata de FKs já existente resolve a exclusão inteira a partir de `auth.users`.

## Backend

### N7 — Edge Function `excluir-conta`
Todas as tabelas do domínio já encadeiam `on delete cascade` até `auth.users`:
`empresas.owner_id → auth.users (cascade)`, e `clientes`/`transacoes`/`contas_pagar_receber`/`membros`/`assinaturas`/`encarregados` → `empresas.id` (cascade), e `ia_uso.user_id → auth.users` (cascade). **Apagar a linha em `auth.users` já apaga tudo em cascata** — não precisa de nenhum delete manual tabela-por-tabela.

Isso só pode ser feito com a `service_role` (o cliente Flutter só tem a chave anônima), então é uma Edge Function nova, seguindo o padrão de `parse-lancamento`/`transcrever-audio`:

1. Cria um client com a chave anônima, repassando o header `Authorization` da requisição, e chama `.auth.getUser()` pra descobrir **quem está chamando** (nunca confiar num `user_id` vindo do corpo da requisição).
2. Se não autenticado, `401`.
3. Cria um segundo client com `SUPABASE_SERVICE_ROLE_KEY` (env var já injetada automaticamente em toda Edge Function do Supabase, sem precisar configurar secret) e chama `auth.admin.deleteUser(user.id)`.
4. Retorna `200 {ok: true}` ou erro.

### N8 — Consentimento
Sem RPC nova — só o `data:` passado ao `signUp()` do lado do Flutter (ver Telas abaixo).

## Telas / UI

### `TermosScreen` (nova, `lib/perfil/termos_screen.dart`)
Tela simples: `AppBar` + `SingleChildScrollView` com o texto (Termos de Uso + Política de Privacidade) em seções (`Text` com títulos em negrito). Conteúdo cobre: o que é o spokfinRM, dados coletados (do dono da conta e dos clientes/fornecedores cadastrados por ele), finalidade, subprocessadores (Supabase, OpenAI), retenção e exclusão, direitos do titular, contato `spokfin@gmail.com`, e uma seção explicando que o usuário MEI é o controlador dos dados dos próprios clientes que cadastra no app. Sem interação além de rolar e voltar.

### `PerfilScreen` (nova, `lib/perfil/perfil_screen.dart`)
Substitui `_abrirMenuPerfil()` em `home_screen.dart` — o `GestureDetector` do avatar (linha ~361) passa a navegar (`Navigator.push`) pra essa tela em vez de abrir o bottom sheet; `_abrirMenuPerfil` e o bottom sheet são removidos.

Estrutura (`ListView`, reaproveitando `AppCard`/`CampoRotulado`/máscaras já existentes):
- Header: `CircleAvatar` com iniciais + nome (razão social) + e-mail (`supabase.auth.currentUser!.email`).
- **INFORMAÇÕES PESSOAIS**: `TextFormField`s em `CampoRotulado` — Nome/Razão Social, Nome Fantasia (opcional), Telefone (opcional, `TelefoneInputFormatter`), CNPJ (opcional, `CpfCnpjInputFormatter`), CPF (opcional, `CpfCnpjInputFormatter`). E-mail mostrado como texto simples (não editável — mudar e-mail de login é um fluxo do Supabase Auth fora de escopo aqui). Botão "Salvar" faz `update` em `empresas`.
- **SUPORTE & INFORMAÇÕES**: um item "Termos de Uso e Privacidade" → `Navigator.push(TermosScreen)`.
- **ZONA DE PERIGO**: "Excluir Minha Conta" (destrutivo, `AppColors.negative` — ação de exclusão, não um botão de salvar, então continua podendo ser vermelho) e "Sair".
  - "Excluir Minha Conta" abre um `AlertDialog` de confirmação explicando que é irreversível e lista o que será apagado (empresa, clientes/fornecedores, lançamentos, assinaturas, encarregados). Ao confirmar: chama `supabase.functions.invoke('excluir-conta')`; em caso de sucesso, chama `supabase.auth.signOut()` (a sessão local já está inválida — o usuário não existe mais — mas isso limpa o estado local e dispara o `AuthGate` a mostrar `LoginScreen`).

### `SignupScreen` (editar)
- Novo `bool _aceitouTermos = false`.
- Abaixo dos campos de e-mail/senha: um `Row` com `Checkbox` + `Expanded(GestureDetector/RichText)` — texto "Li e aceito os " + link tocável "Termos de Uso e Política de Privacidade" (abre `TermosScreen`) + " ." — mesmo texto/link usado no Perfil.
- `FilledButton` de "Criar conta": `onPressed: (_loading || !_aceitouTermos) ? null : _submit`.
- `_submit()`: passa `data: {'termos_aceitos_em': DateTime.now().toUtc().toIso8601String()}` pro `supabase.auth.signUp(...)`.

## Decisões técnicas e alternativas consideradas
- **Cascata de FK em vez de deletes manuais tabela-por-tabela pra N7**: o schema já tem `on delete cascade` em toda a cadeia até `auth.users` (confirmado lendo as migrations 0001/0003/0005/0006/0010) — apagar o `auth.users` já é suficiente. Fazer deletes manuais seria redundante e arriscaria esquecer uma tabela nova que apareça no futuro (ex: se uma tabela nova esquecer o `on delete cascade`, o bug fica óbvio — a linha trava o delete do usuário — em vez de silenciosamente deixar dado órfão, que é o risco de fazer manual).
- **Consentimento em `user_metadata` em vez de tabela própria**: uma tabela só pra guardar `(user_id, aceito_em)` seria uma abstração a mais pra um dado que (a) não precisa ser consultado por nenhuma tela do app, só existir como registro, e (b) já morre sozinho com o cascade de N7 se ficasse numa tabela própria referenciando `auth.users` — `user_metadata` dá o mesmo resultado com menos peça nova.
- **Telefone como único campo novo no schema**: os outros campos do mockup de Perfil (Nome Completo, Nome do Negócio, CNPJ/CPF) já existem; só "Nome Completo" versus "Nome do Negócio" como conceitos separados não existe — decidido reaproveitar `razao_social` pra isso (é o que o app já trata como "nome" do dono/negócio desde o onboarding) em vez de criar um conceito novo de identidade pessoal separada da identidade do negócio.

## Riscos / dependências
- A Edge Function `excluir-conta` precisa ser implantada no Supabase pelo usuário (mesmo fluxo manual já usado pra `parse-lancamento`/`transcrever-audio`) — vou deixar isso claro no `tasks.md` e avisar ao final.
- Migration `0013_empresa_telefone.sql` precisa ser rodada manualmente no SQL Editor do Supabase, como todas as anteriores.
