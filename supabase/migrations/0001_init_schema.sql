-- Fase 1: schema inicial do spokfinRM
-- Cada empresa (1 CNPJ) pertence a um usuário do Supabase Auth.
-- Isolamento entre contas é feito via RLS: toda leitura/escrita passa pelo owner_id da empresa.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- empresas (a "conta" — 1 CNPJ por conta, conforme decisão do produto)
-- ---------------------------------------------------------------------------
create table empresas (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  cnpj text not null unique,
  razao_social text not null,
  nome_fantasia text,
  created_at timestamptz not null default now()
);

create index empresas_owner_id_idx on empresas (owner_id);

-- ---------------------------------------------------------------------------
-- clientes
-- ---------------------------------------------------------------------------
create table clientes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  nome text not null,
  documento text,
  email text,
  telefone text,
  quer_nota_fiscal boolean not null default false,
  created_at timestamptz not null default now()
);

create index clientes_empresa_id_idx on clientes (empresa_id);

-- ---------------------------------------------------------------------------
-- transacoes (histórico — dinheiro que já entrou ou saiu de fato)
-- ---------------------------------------------------------------------------
create table transacoes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid references clientes (id) on delete set null,
  tipo text not null check (tipo in ('entrada', 'saida')),
  categoria text,
  descricao text,
  valor numeric(14, 2) not null check (valor > 0),
  data_transacao date not null default current_date,
  nota_fiscal_status text not null default 'nao_aplicavel'
    check (nota_fiscal_status in ('nao_aplicavel', 'pendente', 'emitida')),
  created_at timestamptz not null default now()
);

create index transacoes_empresa_id_idx on transacoes (empresa_id);
create index transacoes_cliente_id_idx on transacoes (cliente_id);

-- ---------------------------------------------------------------------------
-- contas_pagar_receber (agendado — ainda não realizado, com vencimento e status)
-- ---------------------------------------------------------------------------
create table contas_pagar_receber (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid references clientes (id) on delete set null,
  tipo text not null check (tipo in ('pagar', 'receber')),
  descricao text,
  valor numeric(14, 2) not null check (valor > 0),
  vencimento date not null,
  status text not null default 'pendente'
    check (status in ('pendente', 'pago', 'atrasado', 'cancelado')),
  nota_fiscal_status text not null default 'nao_aplicavel'
    check (nota_fiscal_status in ('nao_aplicavel', 'pendente', 'emitida')),
  transacao_id uuid references transacoes (id) on delete set null,
  created_at timestamptz not null default now()
);

create index contas_pagar_receber_empresa_id_idx on contas_pagar_receber (empresa_id);
create index contas_pagar_receber_cliente_id_idx on contas_pagar_receber (cliente_id);
create index contas_pagar_receber_vencimento_idx on contas_pagar_receber (vencimento);

-- ---------------------------------------------------------------------------
-- RLS: cada conta só enxerga os próprios dados
-- ---------------------------------------------------------------------------
alter table empresas enable row level security;
alter table clientes enable row level security;
alter table transacoes enable row level security;
alter table contas_pagar_receber enable row level security;

create policy empresas_owner_all on empresas
  for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy clientes_owner_all on clientes
  for all
  using (exists (
    select 1 from empresas e
    where e.id = clientes.empresa_id and e.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from empresas e
    where e.id = clientes.empresa_id and e.owner_id = auth.uid()
  ));

create policy transacoes_owner_all on transacoes
  for all
  using (exists (
    select 1 from empresas e
    where e.id = transacoes.empresa_id and e.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from empresas e
    where e.id = transacoes.empresa_id and e.owner_id = auth.uid()
  ));

create policy contas_pagar_receber_owner_all on contas_pagar_receber
  for all
  using (exists (
    select 1 from empresas e
    where e.id = contas_pagar_receber.empresa_id and e.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from empresas e
    where e.id = contas_pagar_receber.empresa_id and e.owner_id = auth.uid()
  ));
