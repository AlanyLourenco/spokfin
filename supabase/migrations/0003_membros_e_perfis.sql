-- Fase 2: perfis de acesso (dono, funcionário, contador) e convite de membros

create table membros (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  email text not null,
  role text not null check (role in ('dono', 'funcionario', 'contador')),
  status text not null default 'convidado' check (status in ('convidado', 'ativo', 'removido')),
  created_at timestamptz not null default now(),
  unique (empresa_id, email)
);

create index membros_empresa_id_idx on membros (empresa_id);
create index membros_user_id_idx on membros (user_id);

-- ---------------------------------------------------------------------------
-- funções auxiliares de autorização — security definer pra ler membros
-- independente da RLS de quem chama, servindo de base pras policies de
-- todas as outras tabelas sem gerar recursão entre elas
-- ---------------------------------------------------------------------------
create function is_member(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from membros
    where empresa_id = p_empresa_id
      and user_id = auth.uid()
      and status = 'ativo'
  );
$$;

create function is_owner(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from membros
    where empresa_id = p_empresa_id
      and user_id = auth.uid()
      and role = 'dono'
      and status = 'ativo'
  );
$$;

grant execute on function is_member(uuid) to authenticated;
grant execute on function is_owner(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- ao criar uma empresa, quem criou vira automaticamente o "dono" ativo
-- ---------------------------------------------------------------------------
create function handle_new_empresa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into membros (empresa_id, user_id, email, role, status)
  values (
    new.id,
    new.owner_id,
    (select email from auth.users where id = new.owner_id),
    'dono',
    'ativo'
  );
  return new;
end;
$$;

create trigger empresas_after_insert
  after insert on empresas
  for each row execute function handle_new_empresa();

-- ---------------------------------------------------------------------------
-- quando um convidado cria conta com o e-mail convidado, ativa o vínculo
-- ---------------------------------------------------------------------------
create function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update membros
  set user_id = new.id, status = 'ativo'
  where email = lower(new.email) and status = 'convidado' and user_id is null;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------------------------
-- convite: só o dono pode convidar funcionário ou contador
-- ---------------------------------------------------------------------------
create function convidar_membro(p_empresa_id uuid, p_email text, p_role text)
returns membros
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_membro membros;
begin
  if not is_owner(p_empresa_id) then
    raise exception 'apenas o dono pode convidar membros';
  end if;

  if p_role not in ('funcionario', 'contador') then
    raise exception 'papel inválido: %', p_role;
  end if;

  insert into membros (empresa_id, email, role, status)
  values (p_empresa_id, lower(p_email), p_role, 'convidado')
  returning * into v_membro;

  return v_membro;
end;
$$;

grant execute on function convidar_membro(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS de membros: qualquer membro ativo vê a equipe; só o dono gerencia
-- ---------------------------------------------------------------------------
alter table membros enable row level security;

create policy membros_select on membros
  for select
  using (is_member(empresa_id));

create policy membros_insert_owner on membros
  for insert
  with check (is_owner(empresa_id));

create policy membros_update_owner on membros
  for update
  using (is_owner(empresa_id))
  with check (is_owner(empresa_id));

create policy membros_delete_owner on membros
  for delete
  using (is_owner(empresa_id));

-- ---------------------------------------------------------------------------
-- troca as policies antigas (baseadas só em owner_id) por policies baseadas
-- em membros — assim funcionário e contador também acessam os dados da
-- empresa em que foram convidados
-- ---------------------------------------------------------------------------
drop policy empresas_owner_all on empresas;
drop policy clientes_owner_all on clientes;
drop policy transacoes_owner_all on transacoes;
drop policy contas_pagar_receber_owner_all on contas_pagar_receber;

create policy empresas_insert on empresas
  for insert
  with check (owner_id = auth.uid());

create policy empresas_select on empresas
  for select
  using (is_member(id));

create policy empresas_update_owner on empresas
  for update
  using (is_owner(id))
  with check (is_owner(id));

create policy empresas_delete_owner on empresas
  for delete
  using (is_owner(id));

create policy clientes_member_all on clientes
  for all
  using (is_member(empresa_id))
  with check (is_member(empresa_id));

create policy transacoes_member_all on transacoes
  for all
  using (is_member(empresa_id))
  with check (is_member(empresa_id));

create policy contas_pagar_receber_member_all on contas_pagar_receber
  for all
  using (is_member(empresa_id))
  with check (is_member(empresa_id));
