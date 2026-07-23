# Tarefas — MRR / Assinantes Mensais

- [x] Migration: tabela `assinaturas` + RLS
- [x] Migration: colunas `assinatura_id`/`competencia` em `transacoes`
- [x] RPC `calcular_mrr(p_empresa_id)`
- [x] View/RPC `assinaturas_com_status(p_empresa_id)`
- [x] RPC `registrar_pagamento_assinatura(p_assinatura_id, p_data)`
- [x] Tela `MrrScreen` (lista + stats Ativos/MRR)
- [x] Tela `NovaAssinaturaScreen`
- [x] Tela `FichaAssinanteScreen` (com "Baixar Pagamento")
- [x] Ligar `MrrScreen` no lugar do placeholder do `MainShell`
- [x] `flutter analyze` limpo
- [ ] Rodar migration no Supabase e testar manualmente no navegador
