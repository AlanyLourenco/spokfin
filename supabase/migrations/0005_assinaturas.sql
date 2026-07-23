-- MRR / Assinantes Mensais (spec: specs/0001-mrr-assinantes)

create table assinaturas (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  cliente_id uuid not null references clientes (id) on delete cascade,
  valor_mensalidade numeric(14, 2) not null check (valor_mensalidade > 0),
  dia_vencimento smallint not null check (dia_vencimento between 1 and 31),
  status text not null default 'ativa' check (status in ('ativa', 'cancelada')),
  created_at timestamptz not null default now()
);

create index assinaturas_empresa_id_idx on assinaturas (empresa_id);
create index assinaturas_cliente_id_idx on assinaturas (cliente_id);

alter table assinaturas enable row level security;

create policy assinaturas_member_all on assinaturas
  for all
  using (is_member(empresa_id))
  with check (is_member(empresa_id));

-- ---------------------------------------------------------------------------
-- transacoes precisa saber a qual assinatura e a qual mês (competência) um
-- pagamento se refere, pra `registrar_pagamento_assinatura` não deixar pagar
-- o mesmo mês duas vezes
-- ---------------------------------------------------------------------------
alter table transacoes
  add column assinatura_id uuid references assinaturas (id) on delete set null,
  add column competencia date;

create index transacoes_assinatura_competencia_idx on transacoes (assinatura_id, competencia);

-- ---------------------------------------------------------------------------
-- MRR: soma das mensalidades das assinaturas ativas
-- ---------------------------------------------------------------------------
create function calcular_mrr(p_empresa_id uuid)
returns numeric
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(sum(valor_mensalidade), 0)
  from assinaturas
  where empresa_id = p_empresa_id and status = 'ativa';
$$;

grant execute on function calcular_mrr(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- status do mês corrente calculado on-demand, sem cron: pago se já existe
-- transação para essa assinatura+mês; senão atrasado/pendente conforme o dia
-- ---------------------------------------------------------------------------
create view assinaturas_com_status
with (security_invoker = true)
as
select
  a.*,
  case
    when exists (
      select 1 from transacoes t
      where t.assinatura_id = a.id
        and t.competencia = date_trunc('month', current_date)::date
    ) then 'pago'
    when extract(day from current_date) > a.dia_vencimento then 'atrasado'
    else 'pendente'
  end as status_mes_atual
from assinaturas a
where a.status = 'ativa';

grant select on assinaturas_com_status to authenticated;

-- ---------------------------------------------------------------------------
-- baixar pagamento de uma assinatura: cria a transação do mês corrente
-- (idempotente por assinatura+competência)
-- ---------------------------------------------------------------------------
create function registrar_pagamento_assinatura(p_assinatura_id uuid, p_data date default current_date)
returns transacoes
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_assinatura assinaturas;
  v_cliente_nome text;
  v_competencia date;
  v_transacao transacoes;
begin
  select * into v_assinatura from assinaturas where id = p_assinatura_id;

  if not found then
    raise exception 'assinatura % não encontrada', p_assinatura_id;
  end if;

  v_competencia := date_trunc('month', p_data)::date;

  if exists (
    select 1 from transacoes
    where assinatura_id = p_assinatura_id and competencia = v_competencia
  ) then
    raise exception 'mensalidade de % já foi paga', to_char(v_competencia, 'MM/YYYY');
  end if;

  select nome into v_cliente_nome from clientes where id = v_assinatura.cliente_id;

  insert into transacoes (
    empresa_id, cliente_id, tipo, categoria, descricao, valor,
    data_transacao, nota_fiscal_status, assinatura_id, competencia
  )
  values (
    v_assinatura.empresa_id,
    v_assinatura.cliente_id,
    'entrada',
    'Assinatura',
    'Mensalidade — ' || coalesce(v_cliente_nome, ''),
    v_assinatura.valor_mensalidade,
    p_data,
    'nao_aplicavel',
    p_assinatura_id,
    v_competencia
  )
  returning * into v_transacao;

  return v_transacao;
end;
$$;

grant execute on function registrar_pagamento_assinatura(uuid, date) to authenticated;
