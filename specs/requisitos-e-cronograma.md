# Requisitos e Cronograma — spokfinRM

Visão consolidada de **tudo** que o projeto precisa (funcional e não-funcional), separando o que já existe do que falta, e uma ordem de execução para o que falta que respeita dependências reais (não dá pra testar em loja de app sem ícone; não dá pra lançar publicamente sem política de privacidade; não dá pra confiar em performance sem paginação testada, etc.).

Este documento não repete os critérios de aceite tela-a-tela — isso já está em [historias-de-usuario.md](historias-de-usuario.md). Aqui o foco é **inventário + prazos relativos + dependências**.

---

## 1. Requisitos Funcionais — Implementados

Catálogo completo com critérios de aceite em [historias-de-usuario.md](historias-de-usuario.md). Resumo por área:

| Área | Status |
|---|---|
| Autenticação (login, cadastro, recuperar senha) | ✅ Completo |
| Onboarding da empresa | ✅ Completo |
| Home (saldo, alertas de vencimento, gráfico de evolução, lançamentos recentes) | ✅ Completo |
| Lançamento — Manual / Anotar (IA texto) / Falar (IA voz) | ✅ Completo |
| Detalhes / Editar / Excluir lançamento | ✅ Completo |
| Nota fiscal (sinalizar + fechar ciclo) | ✅ Completo |
| Recibo em PDF (client-side, sem persistência) | ✅ Completo |
| Histórico (filtros, busca, período, exportar PDF) | ✅ Completo |
| Clientes (lista, busca, cadastro, excluir/arquivar) | ✅ Completo |
| Ficha do Cliente (débito, total pago, serviços prestados, encarregados) | ✅ Completo |
| MRR / Assinantes Mensais | ✅ Completo |
| Aba Balanço (balancete mensal) | ✅ Completo |
| Avisos in-app (vencimento + assinatura atrasada) | ✅ Completo |
| Navegação (shell, ações rápidas) | ✅ Completo |

Migrations `0009_arquivar_cliente.sql` e `0010_rate_limit_ia.sql` já foram rodadas no Supabase — nenhuma pendência operacional em aberto no momento.

---

## 2. Requisitos Funcionais — Pendentes/Futuros

| # | Requisito | Por que ainda não existe |
|---|---|---|
| F1 | Tela de Equipe (convidar funcionário/contador) | Backend (`membros`, `convidar_membro`) já existe desde a Fase 2; decisão explícita de deixar fora de escopo enquanto o uso é solo (um dono por empresa) |
| F2 | Notificação push nativa (fora do app aberto) | Hoje os avisos só aparecem dentro do app (Home); push de verdade exige decisão de mecanismo (`flutter_local_notifications`, FCM/APNs) e permissões de SO |
| F3 | Cobrança da assinatura do próprio spokfinRM (Fase 3 do roadmap original) | Monetização do SaaS em si — diferente do MRR do usuário (que já cobra os *próprios* clientes) |
| F4 | DRE detalhado por categoria na aba Balanço | Decisão explícita de começar simples (receitas x despesas x líquido); detalhamento por categoria fica pra quando houver demanda |

---

## 3. Requisitos Não-Funcionais — Atendidos

| Categoria | O que já existe |
|---|---|
| Segurança de dados | RLS em todas as tabelas via `is_member`/`is_owner` (security definer functions); cada empresa só vê os próprios dados |
| Autenticação | Supabase Auth (e-mail/senha), recuperação de senha completa dentro do app |
| Segredos | `OPENAI_API_KEY` só existe no servidor (Edge Functions); nunca exposta ao cliente Flutter |
| Persistência de PDF | Recibo e relatório de período são gerados 100% client-side e compartilhados via share sheet nativo — nada fica armazenado no Supabase Storage, então não há dado sensível "esquecido" em disco |
| Qualidade de código | `flutter_lints` configurado, `flutter analyze` limpo em todo o projeto |
| Convenção de mudança | Prática de SDD (`specs/NNNN-nome/requirements.md` → `design.md` → `tasks.md`) para toda feature nova a partir da Fase 2 |
| Testes automatizados (N1) | `test/wav_encoder_test.dart`, `test/lancamento_extraido_test.dart`, `test/widget_test.dart` — cobrem a lógica pura testável em Dart (WAV encoding, parsing da extração de IA); regras de negócio que vivem só em SQL (`calcular_saldo` etc.) ainda não têm teste automatizado — ver nota em N1 abaixo |
| CI (N2) | GitHub Actions (`.github/workflows/ci.yml`) rodando `flutter analyze` + `flutter test` a cada push, no repositório `github.com/AlanyLourenco/spokfin` |
| Rate limiting nas Edge Functions de IA (N4) | Migration `0010_rate_limit_ia.sql` (tabela `ia_uso` + RPC `registrar_uso_ia`) — 30 chamadas/hora por usuário, checado antes de gastar com a OpenAI em `parse-lancamento` e `transcrever-audio` |
| Paginação nas listas (N5) | Histórico (limite crescente sobre as 2 fontes mescladas + "Carregar mais"), Clientes (keyset por `nome` + busca server-side com debounce) e MRR (keyset por `created_at`) — todas em páginas de 30 itens |
| Política de Privacidade + Termos de Uso (N6) | `TermosScreen` (specs/0005) — rascunho técnico-funcional; revisão por advogado ainda recomendada antes de lançamento público |
| Exclusão de conta e dados (N7) | `PerfilScreen` → Edge Function `excluir-conta`, cascata de FK já existente (specs/0005) |
| Consentimento explícito no cadastro (N8) | Checkbox obrigatório em `SignupScreen`, timestamp em `user_metadata` (specs/0005) |

---

## 4. Requisitos Não-Funcionais — Pendentes

| # | Requisito | Categoria | Impacto se não resolvido |
|---|---|---|---|
| N1' | Testes automatizados para regras de negócio que vivem só em SQL (`calcular_saldo`, troca pago↔pendente, RLS) | Qualidade | A parte Dart-testável de N1 já foi feita; falta a parte que exigiria um projeto Supabase de teste (pgTAP ou script de integração) — decisão de infra em aberto |
| N3 | Monitoramento de erros em produção (ex: Sentry) | Observabilidade | Hoje um erro em produção só aparece se o usuário reportar — adiado a pedido até a Fase E (produção) |
| N9 | Ícone de app e splash screen personalizados | Distribuição | Hoje usa o ícone/splash padrão do Flutter — bloqueador de fato para lojas (Apple/Google rejeitam ícone padrão) |
| N10 | Teste real em emulador/dispositivo Android e iOS | Distribuição | Todo o desenvolvimento e teste desta sessão foi via `flutter run -d chrome`/web-server; mobile nunca foi validado de fato, apesar do projeto ter os diretórios `android/`/`ios/` desde a Fase 0 |
| N11 | Deploy web de produção (hosting + domínio + HTTPS) | Distribuição | Hoje só roda em `localhost` durante desenvolvimento |
| N12 | Publicação nas lojas (Google Play / App Store) | Distribuição | Depende de conta de desenvolvedor (custo: única vez ~US$25 Google, ~US$99/ano Apple) — decisão de produto, não só técnica |
| N13 | Confirmar plano/tier do Supabase (backup automático, limites de linha/storage) | Confiabilidade | Plano gratuito tem backup e limites diferentes do pago; decisão de produto |

---

## 5. Cronograma de Execução

Ordenado por **dependência real** — cada fase assume que a anterior está pronta. Fases sem dependência cruzada entre si podem rodar em paralelo (indicado abaixo).

```mermaid
flowchart TD
    A["Fase A — Destravar o que já está pronto ✅"] --> B["Fase B — Rede de segurança técnica ✅"]
    B --> C["Fase C — Performance ✅"]
    B --> D["Fase D — Conformidade legal (LGPD) ✅"]
    C --> E["Fase E — Preparar distribuição"]
    D --> E
    E --> F["Fase F — Publicar e expandir"]

    A1["Rodar migrations 0009/0010 ✅"] --> A
    A2["Confirmar plano Supabase (N13)"] --> A

    B1["Testes automatizados Dart (N1) ✅"] --> B2["CI (N2) ✅"]
    B3["Monitoramento de erros (N3) — adiado p/ Fase E"] --> B
    B4["Rate limiting Edge Functions (N4) ✅"] --> B
    B1 --> B

    C1["Paginação nas listas (N5) ✅"] --> C

    D1["Política de Privacidade + Termos (N6) ✅"] --> D2["Consentimento no cadastro (N8) ✅"]
    D3["Exclusão de conta/dados (N7) ✅"] --> D

    E1["Ícone e splash (N9)"] --> E
    E2["Deploy web produção (N11)"] --> E
    E3["Teste real Android/iOS (N10)"] --> E

    F1["Publicação nas lojas (N12)"] --> F
    F2["Tela de Equipe (F1)"] --> F
    F3["Notificação push nativa (F2)"] --> F
```

### Fase A — Destravar o que já está pronto ✅
- ✅ Migrations `0009_arquivar_cliente.sql` e `0010_rate_limit_ia.sql` rodadas no Supabase.
- ⚠️ **N13** ainda em aberto: confirmar/decidir o plano Supabase (backup automático e limites) antes de crescer a base de dados.

### Fase B — Rede de segurança técnica ✅ (parcial)
- ✅ **N1 (parte Dart)** Testes automatizados da lógica pura testável em Flutter (WAV encoder, parsing da extração de IA).
- ⚠️ **N1'** Falta a parte que exigiria infraestrutura de teste separada (regras que vivem só em SQL: `calcular_saldo`, troca pago↔pendente, RLS) — decisão de infra em aberto (pgTAP vs. projeto Supabase de teste).
- ✅ **N2** CI (GitHub Actions) rodando `flutter analyze` + os testes de N1 a cada push, repositório `github.com/AlanyLourenco/spokfin`.
- ⏸️ **N3** Monitoramento de erros — adiado a pedido para a Fase E (quando o app for para produção).
- ✅ **N4** Rate limiting nas Edge Functions de IA (30 chamadas/hora por usuário).

### Fase C — Performance ✅
- ✅ **N5** Paginação em Histórico (páginas de 30, mesclando 2 fontes), Clientes (keyset por nome + busca server-side) e MRR (keyset por `created_at`).

### Fase D — Conformidade legal (LGPD) ✅
- ✅ **N6** Política de Privacidade + Termos de Uso (`TermosScreen`, specs/0005) — rascunho técnico-funcional; ainda recomendado revisar com advogado antes de lançar publicamente.
- ✅ **N8** Consentimento explícito no cadastro (checkbox obrigatório em `SignupScreen`, timestamp salvo no `user_metadata`).
- ✅ **N7** Fluxo de exclusão de conta e dados do usuário (`PerfilScreen` → Edge Function `excluir-conta`, cascata de FK já existente cuida do resto). Migration `0013` rodada e função implantada.

### Fase E — Preparar distribuição
*Depende de C e D estarem prontas — não faz sentido publicar um app sem paginação (trava com muitos dados) ou sem política de privacidade (rejeitado/ilegal).*
- **N9** Ícone e splash screen personalizados.
- **N11** Deploy web de produção (hosting, domínio, HTTPS).
- **N10** Teste real em emulador/dispositivo Android e iOS.

### Fase F — Publicar e expandir
*Depende inteiramente da Fase E.*
- **N12** Publicação nas lojas (Google Play / App Store) — depende de N9 e N10 prontos, mais decisão de orçamento (contas de desenvolvedor).
- **F1** Tela de Equipe (convidar funcionário/contador) — tecnicamente independente, mas faz mais sentido priorizar depois que o produto está publicado e há motivo real para múltiplos usuários por empresa.
- **F2** Notificação push nativa — depende de N10 (app já validado em dispositivo real) para o teste de notificação fazer sentido.

---

## 6. Como manter este documento vivo

- Ao concluir um item, marque-o (✅) tanto aqui quanto (se for funcional) em [historias-de-usuario.md](historias-de-usuario.md).
- Qualquer item da Fase A-F que vire trabalho de verdade deve gerar uma spec própria em `specs/NNNN-nome/`, seguindo o fluxo normal de SDD.
- Se a ordem das fases mudar (ex: decisão de priorizar lojas antes de LGPD), atualize o diagrama e a justificativa de dependência — não só a lista.
