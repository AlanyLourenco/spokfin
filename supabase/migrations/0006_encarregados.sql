-- Ficha do Cliente: encarregados (spec: specs/0002-ficha-cliente)

create table encarregados (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid not null references clientes (id) on delete cascade,
  nome text not null,
  cargo text,
  telefone text,
  created_at timestamptz not null default now()
);

create index encarregados_empresa_id_idx on encarregados (empresa_id);
create index encarregados_cliente_id_idx on encarregados (cliente_id);

alter table encarregados enable row level security;

create policy encarregados_member_all on encarregados
  for all
  using (is_member(empresa_id))
  with check (is_member(empresa_id));
