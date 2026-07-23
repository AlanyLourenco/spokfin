# Design — MRR / Assinantes Mensais

## Modelagem de dados

### Tabela nova: `assinaturas`
```sql
create table assinaturas (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid not null references clientes (id) on delete cascade,
  valor_mensalidade numeric(14, 2) not null check (valor_mensalidade > 0),
  dia_vencimento smallint not null check (dia_vencimento between 1 and 31),
  status text not null default 'ativa' check (status in ('ativa', 'cancelada')),
  created_at timestamptz not null default now()
);
```
RLS: mesmo padrão das outras tabelas de negócio — `is_member(empresa_id)` para tudo.

### Alteração em `transacoes`
Duas colunas novas, para saber a qual assinatura e a qual mês (competência) um pagamento se refere:
```sql
alter table transacoes
  add column assinatura_id uuid references assinaturas (id) on delete set null,
  add column competencia date;
```
`competencia` é sempre o primeiro dia do mês (`date_trunc('month', data_transacao)`), usado como chave de "já foi pago esse mês?".

## Backend

- **`calcular_mrr(p_empresa_id)`** — `sum(valor_mensalidade)` de assinaturas com `status = 'ativa'`.
- **`assinaturas_com_status(p_empresa_id)`** (view ou função retornando tabela) — cada assinatura + `status_mes_atual`:
  - `'pago'` se existe transação com `assinatura_id` e `competencia` = mês corrente
  - senão `'atrasado'` se hoje > dia_vencimento deste mês
  - senão `'pendente'`
- **`registrar_pagamento_assinatura(p_assinatura_id, p_data date default current_date)`** — RPC que:
  1. Busca a assinatura (empresa_id, cliente_id, valor_mensalidade)
  2. Calcula `competencia = date_trunc('month', p_data)`
  3. Levanta exceção se já existe transação para essa assinatura+competência (evita pagar duas vezes o mesmo mês)
  4. Insere em `transacoes`: `tipo='entrada'`, `categoria='Assinatura'`, `descricao='Mensalidade — {nome do cliente}'`, `valor`, `assinatura_id`, `competencia`, `nota_fiscal_status='nao_aplicavel'`
  5. Retorna a transação criada

Todas as funções `security invoker` (RLS garante isolamento), seguindo o padrão de `calcular_saldo`/`registrar_pagamento` já existentes.

## Telas

- **`MrrScreen`** (substitui o placeholder "em breve" na aba MRR do `MainShell`) — cards "Ativos" e "MRR" no topo, lista de assinaturas (avatar iniciais do cliente, valor/mês, dia de vencimento, badge Pago/Atrasado/Pendente), botão "+ Nova" no AppBar.
- **`NovaAssinaturaScreen`** — seleciona cliente (dropdown da tabela `clientes` já cadastrados), valor da mensalidade (mesmo padrão de número grande + chips +R$10/+R$50/+R$100 do formulário de lançamento), dia de vencimento (stepper 1–31), Salvar.
- **`FichaAssinanteScreen`** — nome do cliente, valor/mês, "assinante há N meses" (a partir de `created_at`), contagem de mensalidades pagas/em atraso, botão "Baixar Pagamento" (chama `registrar_pagamento_assinatura`) quando o mês atual está pendente/atrasado, lista das transações passadas vinculadas a essa assinatura.

Reaproveita `AppCard`, `ChoiceChip`/badges e paleta do `theme.dart` já existentes — sem componente novo de design system.

## Decisões técnicas
- Sem cron: o "mês atual" é sempre calculado na hora que a tela abre, nunca persistido antecipadamente. Consequência aceita: se o usuário não abrir o app num mês, não há registro de "pendente" daquele mês até ele abrir — mas isso não afeta o cálculo de saldo, só a exibição.
- `registrar_pagamento_assinatura` é uma função separada de `registrar_pagamento` (que fecha uma `conta_pagar_receber` avulsa) porque a origem e a chave de idempotência (assinatura+competência) são diferentes.

## Riscos / dependências
- Depende da tabela `clientes` já existir (existe, Fase 2).
- "Mensalidades pagas/em atraso" na Ficha do Assinante conta a partir de `created_at` da assinatura — meses anteriores à assinatura não contam.
