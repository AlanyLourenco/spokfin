# Design — Ficha do Cliente

## Modelagem de dados

### Tabela nova: `encarregados`
```sql
create table encarregados (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid not null references clientes (id) on delete cascade,
  nome text not null,
  cargo text,
  telefone text,
  created_at timestamptz not null default now()
);
```
RLS: `is_member(empresa_id)` — mesmo padrão de sempre. `empresa_id` é redundante com `clientes.empresa_id`, mas evita subquery na policy.

Nenhuma outra alteração de schema é necessária — todos os outros números (débito, total pago, serviços prestados, histórico, interações por mês) são derivados de `transacoes` e `contas_pagar_receber`, que já têm `cliente_id`.

## Backend
Nenhuma função nova. Todos os agregados são calculados no cliente (Dart), buscando as linhas de `transacoes`/`contas_pagar_receber` filtradas por `cliente_id` — mesmo padrão já usado em `HomeTabContent` e `HistoricoScreen`. Evita criar uma função SQL para cada estatística.

Para a lista de clientes (débito + último lançamento por cliente), busca-se todas as `transacoes` e `contas_pagar_receber` da empresa de uma vez e agrupa-se por `cliente_id` no Dart — uma query, não N+1.

## Telas

- **`ClientesScreen`** — "Novo" migra do FAB pro AppBar. Linha de cada cliente ganha "Último: {data}" e badge de débito/OK. Tap abre `FichaClienteScreen`.
- **`FichaClienteScreen`** (nova) — nome/telefone/Editar, card de status, cards Total Pago + Serviços Prestados, mini gráfico de barras "Interações por mês" (reaproveita o padrão do `Waveform`, sem depender de pacote de gráficos), seção Encarregados (lista + "Adicionar"), seção Histórico.
- **`AdicionarEncarregadoScreen`** ou diálogo simples — nome, cargo, telefone.
- **`QuickActionsSpeedDial`** (novo widget) — FAB expansível com Falar/Anotar/Manual, usado no `MainShell` nas abas Clientes/Histórico/MRR/Balanço (a Home mantém sua própria barra de ações já existente, sem duplicar).

## Decisões técnicas
- Sem função SQL nova: menos migração, e o padrão de agregação client-side já está estabelecido no projeto (consistência > "seria mais eficiente no banco").
- Mini gráfico de interações: componente próprio (barras simples), não vale adicionar um pacote de charts pra isso.

## Riscos / dependências
- `FichaClienteScreen` depende de `clientes`, `transacoes` e `contas_pagar_receber` já existirem (existem).
- Débito por cliente considera só `contas_pagar_receber` com `tipo='receber'` e `status='pendente'` — mesma lógica já usada no card "A Receber" da Home.
