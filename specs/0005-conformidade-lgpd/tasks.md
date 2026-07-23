# Tarefas — Conformidade Legal (LGPD)

- [x] Migration `supabase/migrations/0013_empresa_telefone.sql` (`alter table empresas add column telefone text`)
- [x] Edge Function `supabase/functions/excluir-conta/index.ts` (verifica JWT do chamador, deleta `auth.users` via `service_role`, cascata cuida do resto)
- [x] `lib/perfil/termos_screen.dart` (texto de Termos de Uso + Política de Privacidade)
- [x] `lib/perfil/perfil_screen.dart` (header, Informações Pessoais editável, link Termos, Excluir Minha Conta, Sair)
- [x] `home_screen.dart`: avatar navega pra `PerfilScreen` em vez de abrir `_abrirMenuPerfil()` (remover o bottom sheet antigo)
- [x] `signup_screen.dart`: checkbox de aceite (desmarcado por padrão), botão "Criar conta" desabilitado até marcar, `data: {'termos_aceitos_em': ...}` no `signUp()`
- [x] `flutter analyze` limpo
- [x] `flutter test` passando
- [x] Commit + push
- [x] Migration 0013 rodada e Edge Function `excluir-conta` implantada pelo usuário
- [ ] Testado manualmente no navegador (cadastro com/sem aceite, editar Perfil, abrir Termos, excluir conta)
- [x] Atualizar índice em `specs/README.md`
- [x] Avisar o usuário: rodar migration `0013` no SQL Editor e implantar a Edge Function `excluir-conta` manualmente no Supabase (nenhuma das duas eu consigo fazer por aqui)
