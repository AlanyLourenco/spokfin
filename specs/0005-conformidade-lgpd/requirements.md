# Requisitos — Conformidade Legal (LGPD)

## Contexto
`specs/requisitos-e-cronograma.md` marca a Fase D (Conformidade legal/LGPD) como a próxima depois da Fase C (performance, concluída). Ela agrupa 3 requisitos não-funcionais pendentes: **N6** (Política de Privacidade + Termos de Uso), **N8** (consentimento explícito no cadastro, depende de N6) e **N7** (fluxo de exclusão de conta e dados do usuário). Hoje o app não tem nenhum documento legal, nenhum checkbox de aceite no cadastro, e a única exclusão que existe é de *cliente/fornecedor* — não existe "excluir minha conta".

O app trata dois tipos de dado pessoal: (a) os dados do próprio usuário dono da empresa (e-mail de login, razão social, CNPJ/CPF opcional) e (b) dados de terceiros que o usuário cadastra sobre os *seus* clientes/fornecedores (nome, telefone, chave PIX). A Política de Privacidade precisa cobrir os dois papéis: o spokfinRM como operador da plataforma, e o usuário MEI como controlador dos dados dos próprios clientes que ele cadastra.

## Objetivo
O app tem um documento de Política de Privacidade + Termos de Uso acessível dentro do app, o cadastro exige aceite explícito antes de criar a conta, e o usuário consegue excluir permanentemente sua conta e todos os dados associados a partir do próprio app.

## Requisitos funcionais

### N6 — Política de Privacidade + Termos de Uso
- [ ] Documento único (Termos de Uso + Política de Privacidade) escrito em português, cobrindo: quais dados são coletados (do dono da conta e dos clientes/fornecedores cadastrados por ele), finalidade, quem processa (Supabase como armazenamento/auth, OpenAI como subprocessador da IA de parsing/transcrição), por quanto tempo os dados ficam guardados, direitos do titular (acesso, correção, exclusão), e o canal de contato `spokfin@gmail.com` para solicitações.
- [ ] Uma tela (`TermosScreen`) renderiza esse texto, acessível a partir do cadastro (link "Li e aceito os Termos de Uso e a Política de Privacidade") e da nova tela de Perfil (item "Termos de Uso e Privacidade").

### N6.1 — Tela de Perfil (mínima)
- [ ] Novo `PerfilScreen`, substituindo o bottom sheet atual `_abrirMenuPerfil()` do Home (o ícone/avatar do cabeçalho passa a navegar pra essa tela em vez de abrir o bottom sheet).
- [ ] Seção **Informações Pessoais**: Nome/Razão Social, Nome Fantasia (opcional), E-mail (somente leitura, vem do auth), Telefone (novo campo, opcional — exige migration pequena `alter table empresas add column telefone text`), CNPJ (opcional), CPF (opcional) — editáveis, reaproveitando `CampoRotulado` + máscaras (`TelefoneInputFormatter`, `CpfCnpjInputFormatter`) já existentes.
- [ ] Seção **Suporte & Informações**: item "Termos de Uso e Privacidade" (abre `TermosScreen`).
- [ ] Seção **Zona de Perigo**: "Excluir Minha Conta" (N7) e "Sair" (reaproveita `supabase.auth.signOut()`).
- [ ] Fora desta tela mínima: Plano & Assinatura, Preferências (idioma/moeda/notificações), Biometria, Exportar Dados, Suporte/FAQ, Versão do App — nenhum desses tem funcionalidade correspondente no app hoje.

### N8 — Consentimento explícito no cadastro
- [ ] `SignupScreen` ganha um checkbox "Li e aceito os Termos de Uso e a Política de Privacidade" (com link tocável pro texto de N6) — desmarcado por padrão.
- [ ] O botão "Criar conta" fica desabilitado até o checkbox ser marcado.
- [ ] Fica registrado (coluna ou tabela) que o usuário aceitou os termos e quando — pra existir prova de consentimento se questionado depois.

### N7 — Exclusão de conta e dados do usuário
- [ ] Um lugar no app (provavelmente Home, junto do botão de logout existente) oferece "Excluir minha conta", com confirmação clara (mostrando que é irreversível e o que será apagado).
- [ ] Excluir a conta apaga: a empresa (`empresas`), e por cascata tudo que pertence a ela (`clientes`, `transacoes`, `contas_pagar_receber`, `assinaturas`, `encarregados`, `ia_uso`), e o próprio usuário (`auth.users`).
- [ ] Como o cliente Flutter só tem a chave anônima (nunca a `service_role`), apagar `auth.users` exige uma Edge Function nova que roda com `service_role` no servidor — mesmo padrão de segredo-só-no-servidor já usado em `parse-lancamento`/`transcrever-audio`.

## Fora de escopo
- Não implementa "exportar meus dados" (portabilidade) — não estava no roadmap original (N6/N7/N8), fica pra um requisito futuro se pedido.
- Não implementa uma tela de "Configurações" completa — só o mínimo pra acomodar o link dos Termos e o botão de excluir conta, reaproveitando a Home.
- O texto legal gerado aqui é um rascunho técnico-funcional, não substitui revisão por advogado antes de lançar publicamente (mesmo já registrado como pendência em N6 no cronograma).

## Decisões confirmadas
- **E-mail de contato pra solicitações de privacidade**: `spokfin@gmail.com`.
- **Exclusão de conta**: imediata e definitiva, sem prazo de carência — ao confirmar, apaga tudo na hora.
- **Acesso pós-login**: nova tela de Perfil (versão mínima, ver N6.1), aberta a partir do avatar do Home, no lugar do bottom sheet atual.

## Perguntas em aberto
Nenhuma.
