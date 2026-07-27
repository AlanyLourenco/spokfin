# Tarefas — Nova Paleta e Tipografia Inter

- [x] Instalar skill `ui-ux-pro-max` (`npm install -g ui-ux-pro-max-cli && uipro init --ai claude`)
- [x] Rodar `--design-system` e `--domain color`/`--domain typography` pra fintech/dashboard escuro
- [x] Confirmar com o usuário: manter verde-menta refinado vs. trocar pra paleta nova (azul+verde escolhido)
- [x] Adicionar Inter via `web/index.html` (Google Fonts, sem pacote novo)
- [x] Reescrever `AppColors`/`buildAppTheme()` em `lib/theme.dart`
- [x] Auditar e migrar as ~40 referências diretas a `AppColors.accent`/`negative` nos 20 arquivos afetados, separando "ação de UI" (azul) de "dinheiro" (verde/vermelho)
- [x] Corrigir 2 bugs de contraste achados durante a migração (spinner invisível no botão Salvar de Detalhes; `Colors.black` cru em `MrrScreen`)
- [x] Reescrever `DESIGN.md` com a nova paleta e a `Two Roles Rule`
- [x] `flutter analyze` limpo
- [x] `flutter test` (44/44)
- [x] Testado visualmente no navegador (Login, Home, Balanço, MRR, Clientes) — paleta aplicada de ponta a ponta, sem erro de console
- [ ] Usuário validar pessoalmente no navegador (`http://localhost:5000`)
