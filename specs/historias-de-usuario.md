# Histórias de Usuário — spokfinRM

Catálogo de todas as histórias de usuário e critérios de aceite do app, organizado por área. Ao contrário das specs em `specs/NNNN-nome/` (que documentam uma feature nova *antes* de construir), este documento é retroativo: registra o comportamento que já existe (extraído do código) e as decisões de produto tomadas em conversa, servindo de referência única do "como deve se comportar" de cada tela.

Ator principal em todas as histórias, salvo indicação contrária: **o MEI** (dono da empresa, usuário do app).

Convenção de status por história:
- ✅ **Implementado** — já está no código, comportamento descrito é o atual.
- 🕳️ **Lacuna** — comportamento decidido nesta rodada de perguntas, mas ainda não implementado. Vira item de backlog (ver seção final).
- 🔭 **Fora de escopo (por ora)** — decisão explícita de não fazer agora.

---

## 1. Autenticação

### 1.1 Login ✅
Como usuário cadastrado, quero entrar com e-mail e senha, para acessar os dados da minha empresa.
- Tela `LoginScreen`; falha de credencial mostra erro inline.

### 1.2 Cadastro (Signup) ✅ + decisão
Como visitante, quero criar uma conta com e-mail e senha, para começar a usar o app.
- **Sem confirmação de e-mail obrigatória** — acesso liberado imediatamente após o cadastro, sem precisar clicar em link de confirmação. Prioriza menos fricção para o MEI, que costuma ser um usuário não-técnico.

### 1.3 Recuperar senha ✅
Como usuário que esqueceu a senha, quero pedir uma nova, para recuperar o acesso sem precisar de suporte.
- **Fluxo completo dentro do app**: usuário informa o e-mail (`forgot_password_screen.dart`) → Supabase envia link → link abre o app, `AuthGate` escuta `AuthChangeEvent.passwordRecovery` e mostra `NovaSenhaScreen` → usuário digita a nova senha (`supabase.auth.updateUser`) e já entra logado, sem passar pela tela de login de novo.

### 1.4 Uma empresa por usuário ✅ (decisão confirmada)
Como usuário, tenho sempre exatamente uma empresa vinculada à minha conta — não existe seletor de empresa/CNPJ no app.
- Se o MEI precisar de outra empresa, cria outra conta. Mantém o app simples.
- (O backend já suporta múltiplos *membros* por empresa — dono/funcionário/contador — mas isso é um eixo diferente: ver [12. Equipe e permissões](#12-equipe-e-permissões-fora-de-escopo-por-ora).)

---

## 2. Onboarding da Empresa

### 2.1 Cadastro inicial da empresa ✅
Como usuário recém-cadastrado, quero informar os dados da minha empresa, para começar a registrar lançamentos.
- **Único campo obrigatório: "Nome da Empresa"** (campo reordenado pro topo do formulário, salvo em `razao_social`). CNPJ, CPF e Nome Fantasia são opcionais e podem ser preenchidos depois — libera o uso imediato mesmo para quem ainda não tem CNPJ em mãos.
- `empresa_setup_screen.dart`: rótulo já era tecnicamente o único obrigatório antes ("Razão Social"), mas foi renomeado para "Nome da Empresa" e movido pra primeiro campo, pra não soar formal/burocrático demais no primeiro contato do MEI com o app.

---

## 3. Home (Dashboard)

### 3.1 Visão geral financeira ✅
Como MEI, quero ver de cara meu saldo atual, quanto tenho a receber e a pagar, para saber a saúde financeira do negócio sem precisar navegar.
- Card "Saldo Atual" (via RPC `calcular_saldo`), mini-stats "A Receber" (verde) e "A Pagar" (vermelho), somando `contas_pagar_receber` pendentes.

### 3.2 Lançamentos recentes ✅
Como MEI, quero ver os últimos lançamentos (pagos e pendentes) direto na Home, para não precisar abrir o Histórico toda vez.
- Lista dos 5 mais recentes (transações + contas não pagas), ordenados por data desc; toque abre `DetalhesLancamentoScreen`.

### 3.3 Registrar lançamento rápido ✅
Como MEI, quero registrar um ganho/gasto em poucos toques, direto da Home, para não perder o momento em que aconteceu.
- Barra inferior fixa com Falar / Anotar / Manual (pill container único, Falar em destaque).

### 3.4 Alerta de vencimento próximo ✅
Como MEI, quero ser avisado visualmente quando uma conta está perto de vencer (antes de virar "atrasado"), para me planejar e não ser pego de surpresa.
- Card "Vencendo em Breve" na Home, com contas pendentes vencendo nos próximos 3 dias (`_diasAlertaVencimento` em `home_screen.dart`), tocável para abrir Detalhes.

### 3.5 Gráfico de evolução do saldo ✅
Como MEI, quero ver a tendência do meu saldo ao longo dos últimos meses, para entender se estou crescendo ou encolhendo.
- Card "Evolução do Saldo" na Home: mini-gráfico de barras (`_SaldoMesChart`) com o líquido mensal (entradas − saídas) dos últimos 6 meses, barra verde/vermelha conforme o sinal.

---

## 4. Registrar Lançamento — Manual / Anotar / Falar

Os três caminhos de entrada convergem na mesma tela de confirmação (`RevisarLancamentoScreen`).

### 4.1 Lançamento manual ✅
Como MEI, quero digitar diretamente valor, descrição, tipo, status, categoria, cliente e data, para registrar um lançamento sem depender da IA.
- Valor: campo de texto numérico editável + chips de atalho (+R$10/+R$50/+R$100/Zerar) que somam ao que já foi digitado.
- Cliente: dropdown com clientes da empresa + atalho "Cadastrar novo cliente" inline.
- Data: seletor de data; rótulo muda para "Data de Vencimento" quando status = Pendente.

### 4.2 Anotar (texto livre + IA) ✅
Como MEI, quero escrever uma frase solta (“recebi 300 do João por consultoria”) e deixar a IA preencher os campos, para economizar tempo comparado ao formulário manual.
- GPT-4o-mini extrai tipo, valor, descrição, categoria, status, nota fiscal, **cliente (nome)** e **data** (resolve termos relativos como "ontem"/"anteontem" a partir da data atual do servidor).
- Nome de cliente extraído é comparado (substring, case-insensitive) com os clientes já cadastrados; se casar, pré-seleciona no dropdown da tela de confirmação — usuário sempre pode corrigir.
- Tudo cai na tela de confirmação para revisão antes de salvar — a IA nunca salva direto.

### 4.3 Falar (áudio + IA) ✅
Como MEI, quero narrar um lançamento em voz alta enquanto estou ocupado, para registrar sem parar o que estou fazendo.
- Grava até 40s (limite silencioso, sem contagem regressiva visível), com waveform real ligado à amplitude do microfone.
- Whisper transcreve → mesmo pipeline de extração do Anotar → tela de confirmação.

### 4.4 Um lançamento por vez 🕳️ (decisão)
Como MEI, se eu falar/escrever mais de um lançamento numa frase só (“recebi 100 do João e paguei 50 de internet”), a IA deve extrair só o principal/mais claro e ignorar o resto.
- Usuário registra o segundo lançamento separadamente. Evita a complexidade de uma tela de confirmação múltipla.

### 4.5 Retry e fallback quando a IA falha ✅
Como MEI, se a transcrição (Falar) ou a extração (Anotar) falhar ou vier claramente errada, quero uma segunda chance antes de desistir.
- `_extrairComRetry`/`_processarComRetry` em `anotar_screen.dart`/`falar_screen.dart`: tenta novamente automaticamente uma vez; se falhar de novo, cai para `RevisarLancamentoScreen` com os campos em branco (lançamento manual), com um snackbar avisando.

### 4.6 Campos obrigatórios para salvar ✅ (mantido como está)
Como MEI, quero poder salvar um lançamento rápido mesmo sem preencher descrição ou categoria, para não perder tempo em registros simples.
- Única validação obrigatória: valor > 0. Descrição e categoria continuam opcionais.

### 4.7 Nota Fiscal — sinalização ✅
Como MEI, quero apenas sinalizar que um cliente pediu nota fiscal, sem que o app tente emitir a NFC-e de verdade.
- Toggle "Emitir Nota Fiscal (NFC-e)?" na confirmação; grava `nota_fiscal_status = pendente` ou `nao_aplicavel`. Emissão real acontece por fora do app.

### 4.8 Fechar o ciclo da nota fiscal ✅
Como MEI, depois de emitir a nota fiscal de verdade (fora do app), quero marcar aquele lançamento como resolvido, para o selo "NFC-e agendada" sumir da lista.
- Card "NFC-e agendada" com botão "Marcar como emitida" em `DetalhesLancamentoScreen`, atualiza `nota_fiscal_status` para `emitida` (valor já previsto no check constraint desde a Fase 0).

---

## 5. Detalhes e Edição do Lançamento

### 5.1 Ver detalhes ✅
Como MEI, quero tocar num lançamento em qualquer lista (Home, Histórico, Ficha do Cliente) e ver todos os seus dados, para conferir ou agir sobre ele.
- `DetalhesLancamentoScreen`: categoria, descrição, valor, data, status, cliente (se houver).

### 5.2 Mudar status pago ↔ pendente ✅
Como MEI, quero marcar uma conta pendente como paga (ou reverter um pagamento por engano), para manter o status real do dinheiro.
- "Marcar Pago" → RPC `registrar_pagamento` (move de `contas_pagar_receber` para `transacoes`).
- "Marcar Pendente" → RPC `marcar_lancamento_pendente` (caminho inverso).
- Sem limite de tempo: qualquer lançamento pode ser editado/ter status alterado a qualquer momento, não importa a idade.

### 5.3 Editar todos os campos ✅
Como MEI, quero corrigir qualquer campo de um lançamento já salvo (valor, descrição, categoria, tipo, status, cliente, data), para consertar um erro de digitação ou de registro.
- `EditarLancamentoScreen` → RPC `atualizar_lancamento`, que lida com a troca de tabela internamente se o status mudar.

### 5.4 Excluir lançamento ✅
Como MEI, quero apagar de vez um lançamento criado por engano (duplicado, teste, valor totalmente errado), para meu histórico ficar limpo.
- Botão "Excluir Lançamento" na tela de Detalhes, com dialog de confirmação antes de apagar (`_confirmarExclusao` em `detalhes_lancamento_screen.dart`). As policies `transacoes_member_all`/`contas_pagar_receber_member_all` já eram `for all`, então o delete já era permitido por RLS — só faltava a UI.

---

## 6. Recibo

### 6.1 Gerar recibo de recebimento ✅
Como MEI, quero gerar um comprovante em PDF de um recebimento já pago, para enviar ao cliente.
- Só aparece para lançamentos do tipo Entrada (`_pago && _entrada` em `detalhes_lancamento_screen.dart`) — um "recibo" representa o comprovante de quem recebeu; para uma Saída (gasto seu) quem emite é o fornecedor.
- Numeração "Recibo #N" por cliente (conta quantos recebimentos pagos aquele cliente específico já teve) — mantido como está, não é sequencial único da empresa.

### 6.2 Compartilhar sem persistência ✅
Como MEI, quero compartilhar o recibo em PDF direto pelo compartilhamento nativo do aparelho (WhatsApp, e-mail, etc.), sem que o arquivo fique guardado em nenhum servidor.
- PDF gerado 100% client-side (`pdf` + `printing`), `Printing.sharePdf(...)`. Nada toca o Supabase Storage — não há nada para expirar ou limpar depois.

---

## 7. Histórico

### 7.1 Listar e filtrar por tipo/texto ✅
Como MEI, quero ver todos os lançamentos (pagos e pendentes) num só lugar, filtrando por tipo ou buscando por descrição, para achar um lançamento específico.
- Filtros Tudo/Entradas/Saídas + busca por texto na descrição (client-side, sobre os itens já carregados).
- **Paginação**: carrega os 30 lançamentos mais recentes de cada fonte (transações + contas), mescla e ordena por data; botão "Carregar mais" amplia o limite em +30 e refaz a busca. Evita carregar o histórico inteiro de uma vez conforme a base cresce.

### 7.2 Filtrar por período ✅
Como MEI, quero ver só os lançamentos de um mês específico (o atual, o passado, ou um intervalo customizado), para fechar as contas de um período sem rolar a lista toda.
- Segunda linha de chips (Todos / Este Mês / Mês Passado / Personalizado) abaixo do filtro de tipo; "Personalizado" abre `showDateRangePicker`.

### 7.3 Exportar relatório de período ✅
Como MEI, quero exportar um relatório (PDF/CSV) de um intervalo de datas, para entregar ao meu contador sem precisar copiar lançamento por lançamento.
- Botão "Exportar período" no Histórico (`_exportarRelatorio`), gera um PDF (tabela de data/descrição/categoria/status/valor + totais de entradas/saídas/saldo) a partir dos itens já filtrados na tela (tipo + período + busca), compartilhado via `Printing.sharePdf` — mesma abordagem client-side do recibo, sem persistência no servidor.

---

## 8. Clientes

### 8.1 Listar clientes com status de débito ✅
Como MEI, quero ver rapidamente quais clientes estão em débito e quais estão em dia, para saber com quem cobrar.
- Lista mostra data do último lançamento e "Em Débito: R$ X" (vermelho) ou "OK" (verde) por cliente — spec [0002](0002-ficha-cliente/requirements.md).

### 8.2 Buscar cliente por nome ✅
Como MEI, quero buscar um cliente pelo nome numa lista que pode crescer bastante, para não precisar rolar até achar.
- Campo de busca no topo de `ClientesScreen`; a busca (com debounce de 300ms) roda **direto no servidor** (`ilike`), não só sobre a página já carregada, então encontra qualquer cliente ativo mesmo que esteja em páginas ainda não carregadas.
- **Paginação**: lista principal (sem busca) usa keyset por `nome` (páginas de 30, "Carregar mais" busca `nome > último carregado`); os agregados de débito/último lançamento são calculados só para os clientes da página atual, não para a empresa inteira.

### 8.3 Cadastrar/editar cliente ✅
Como MEI, quero cadastrar um novo cliente (nome, telefone) ou editar um existente, para manter minha base de clientes atualizada.
- `cliente_form_screen.dart`.

### 8.4 Excluir cliente ✅
Como MEI, quero remover um cliente que não faz mais sentido manter na lista.
- **Se o cliente tiver lançamentos vinculados, a exclusão é bloqueada** — `_excluirOuArquivar` em `ficha_cliente_screen.dart` checa `transacoes`/`contas_pagar_receber` por `cliente_id`; se houver algum, oferece "Arquivar" (seta `ativo = false`, migration `0009_arquivar_cliente.sql`) em vez de apagar, preservando o histórico. Exclusão de verdade só é permitida para clientes sem nenhum lançamento vinculado. `ClientesScreen` já filtra `ativo = true`.

### 8.5 Ficha do Cliente completa ✅
Como MEI, quero abrir a ficha de um cliente e ver débito, total pago, serviços prestados, histórico e encarregados, tudo num só lugar — spec [0002](0002-ficha-cliente/requirements.md), já detalhada lá (cards de status, "Serviços Prestados" = contagem de lançamentos, gráfico de interações por mês, seção Encarregados).

### 8.6 Encarregados (contatos secundários) ✅
Como MEI, quero registrar mais de um contato por cliente (ex.: financeiro, responsável técnico), para saber com quem falar sobre o quê — spec [0002](0002-ficha-cliente/requirements.md). Fora de escopo (já decidido lá): editar/excluir encarregado individualmente, e vincular lançamento a um encarregado específico (o vínculo é sempre com o cliente).

---

## 9. MRR / Assinantes Mensais

Já especificado em [0001-mrr-assinantes](0001-mrr-assinantes/requirements.md): criar assinatura (cliente + valor + dia de vencimento), listar assinantes ativos com status do mês, MRR total, ficha do assinante com histórico de cobranças, "Baixar Pagamento" (RPC `registrar_pagamento_assinatura`), editar/cancelar assinatura. Status calculado on-demand, sem cron.

**Paginação**: a lista de assinantes usa keyset por `created_at` (páginas de 30, "Carregar mais"); os cards "Ativos" e "MRR" continuam refletindo o total real da empresa (RPC `calcular_mrr` + contagem separada), não só o que está carregado na tela.

---

## 10. Aba Balanço

### 10.1 Balancete mensal ✅
Como MEI, quero ver um resumo do mês (receitas x despesas x lucro líquido), para saber se o mês fechou positivo ou negativo sem precisar somar na mão.
- `BalancoScreen`: seletor de mês (setas anterior/seguinte), card de Lucro Líquido e cards de Receitas/Despesas, somando `transacoes` pagas do mês selecionado. Versão simples — não é um DRE detalhado por categoria; isso fica para uma iteração futura, se necessário.

---

## 11. Notificações e lembretes ✅ (versão in-app)

Como MEI, quero ser avisado dentro do app quando:
- uma conta a pagar/receber está perto de vencer — card "Vencendo em Breve" na Home ([3.4](#34-alerta-de-vencimento-próximo-)).
- uma assinatura (MRR) atrasou o pagamento do mês — novo card "Assinaturas Atrasadas" na Home, lista `assinaturas_com_status` com `status_mes_atual = 'atrasado'`, toque abre a Ficha do Assinante.
- Push/notificação nativa do sistema operacional (fora do app aberto) continua fora de escopo — isso exigiria um `design.md` próprio (permissões, agendamento, `flutter_local_notifications` ou similar) se/quando for priorizado.

---

## 12. Equipe e permissões 🔭 (fora de escopo por ora)

O backend (`membros`, `convidar_membro`, roles `dono`/`funcionario`/`contador`) já existe desde a Fase 2, mas **não há nenhuma tela no app** para convidar ou gerenciar membros — o uso hoje é sempre solo (um dono por empresa). Decisão: manter fora do catálogo de histórias por ora; revisitar se/quando o produto precisar de múltiplos usuários por empresa. Quando entrar em escopo, decidir também se funcionário/contador têm alguma restrição de ação em relação ao dono (ainda não definido).

---

## 13. Navegação (Shell)

### 13.1 Navegação por abas ✅
Como MEI, quero alternar entre Home, Balanço, MRR, Histórico e Clientes por uma barra inferior fixa, para acessar qualquer área em um toque.
- `MainShell`: `IndexedStack` preserva o estado de cada aba ao trocar.

### 13.2 Ações rápidas nas outras abas ✅
Como MEI, quero registrar um lançamento (Falar/Anotar/Manual) mesmo estando em Clientes, Histórico, MRR ou Balanço, sem precisar voltar pra Home.
- `QuickActionsSpeedDial` (FAB expansível), oculto só na aba Home (que já tem a barra inline).

---

## Lacunas identificadas — status

Todas as lacunas identificadas na primeira rodada deste catálogo foram implementadas:

1. ✅ Tela "Definir nova senha" (`nova_senha_screen.dart` + `AuthGate` escutando `passwordRecovery`) — [1.3](#13-recuperar-senha-)
2. ✅ Onboarding: "Nome da Empresa" como único campo obrigatório — [2.1](#21-cadastro-inicial-da-empresa-)
3. ✅ Alerta de vencimento próximo na Home — [3.4](#34-alerta-de-vencimento-próximo-)
4. ✅ Gráfico de evolução do saldo na Home — [3.5](#35-gráfico-de-evolução-do-saldo-)
5. ✅ Retry automático (1x) + fallback pro manual quando Anotar/Falar falham — [4.5](#45-retry-e-fallback-quando-a-ia-falha-)
6. ✅ Fechar o ciclo da nota fiscal (pendente → emitida) — [4.8](#48-fechar-o-ciclo-da-nota-fiscal-)
7. ✅ Excluir lançamento (com confirmação) — [5.4](#54-excluir-lançamento-)
8. ✅ Restringir "Gerar Recibo" a Entrada — [6.1](#61-gerar-recibo-de-recebimento-)
9. ✅ Filtro de período no Histórico — [7.2](#72-filtrar-por-período-)
10. ✅ Exportar relatório de período (PDF) — [7.3](#73-exportar-relatório-de-período-)
11. ✅ Busca por nome na lista de Clientes — [8.2](#82-buscar-cliente-por-nome-)
12. ✅ Excluir cliente (bloqueado se tiver lançamentos, com arquivamento) — [8.4](#84-excluir-cliente-) — **requer rodar a migration `0009_arquivar_cliente.sql` no Supabase**
13. ✅ Aba Balanço: balancete mensal simples — [10.1](#101-balancete-mensal-)
14. ✅ Notificações/avisos in-app (vencimento + assinatura atrasada) — [11](#11-notificações-e-lembretes--versão-in-app)

Não resta nenhuma lacuna aberta deste catálogo. Itens fora de escopo permanecem documentados por decisão explícita: [Equipe e permissões](#12-equipe-e-permissões-fora-de-escopo-por-ora) e notificação push nativa (fora do app aberto), ambos citados nas seções correspondentes. Qualquer feature nova a partir daqui deve virar spec própria em `specs/NNNN-nome/`, seguindo o fluxo normal de SDD (`requirements.md` → `design.md` → `tasks.md`).
