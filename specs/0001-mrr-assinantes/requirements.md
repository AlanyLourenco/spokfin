# Requisitos — MRR / Assinantes Mensais

## Contexto
O protótipo Lovable tem uma aba "MRR" com assinantes mensais recorrentes — clientes do próprio MEI que pagam uma mensalidade fixa (ex: "João paga R$ 200 todo dia 5"). Isso é diferente da cobrança da assinatura do spokfinRM em si (Fase 3 do roteiro) — aqui é o negócio do usuário cobrando os *próprios* clientes de forma recorrente.

## Objetivo
O usuário cadastra uma assinatura mensal para um cliente, vê o MRR total (soma das mensalidades ativas) e a contagem de assinantes ativos, e acompanha/baixa o pagamento de cada mês.

## Requisitos funcionais
- [ ] Criar uma assinatura: cliente, valor da mensalidade, dia de vencimento (1–31)
- [ ] Listar assinaturas ativas: nome do cliente, valor, dia de vencimento, status do mês atual (pago/atrasado)
- [ ] Exibir MRR total (soma das mensalidades ativas) e contagem de "Ativos"
- [ ] Abrir a "ficha do assinante": mensalidades pagas, mensalidades em atraso, histórico de cobranças por mês
- [ ] "Baixar Pagamento" de uma cobrança do mês — gera uma transação real (entrada) vinculada
- [ ] Editar valor/vencimento ou cancelar uma assinatura

## Fora de escopo
- Cobrança automática via Pix/cartão (Fase 3 — cobrança da assinatura do próprio spokfinRM)
- Lembrete automático de cobrança por e-mail/WhatsApp (Fase 3 — avisos automáticos)
- Qualquer processo agendado (cron) rodando no servidor sem o app aberto

## Decisões
1. **Geração da cobrança mensal: on-demand.** Nenhum cron. Uma função verifica, para o mês corrente, se já existe uma transação de pagamento daquela assinatura; se não existir, o mês aparece como pendente. Só grava algo quando o usuário confirma o pagamento.
2. **"Baixar Pagamento" terá seu próprio RPC** (`registrar_pagamento_assinatura`), já que a origem é uma assinatura recorrente, não uma `conta_pagar_receber` avulsa — mas internamente insere em `transacoes` do mesmo jeito que `registrar_pagamento` já faz.
