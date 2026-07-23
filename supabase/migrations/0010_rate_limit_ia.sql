-- Rate limiting nas Edge Functions de IA (parse-lancamento, transcrever-audio):
-- protege contra custo de API descontrolado por uso indevido ou bug em loop.
-- Checagem é best-effort (não 100% atômica sob concorrência alta), suficiente
-- pro perfil de uso de um MEI (poucas chamadas sequenciais, não concorrentes).

create table ia_uso (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  funcao text not null check (funcao in ('parse-lancamento', 'transcrever-audio')),
  criado_em timestamptz not null default now()
);

create index ia_uso_user_id_criado_em_idx on ia_uso (user_id, criado_em);

alter table ia_uso enable row level security;

create policy ia_uso_select_own on ia_uso
  for select
  using (user_id = auth.uid());

create policy ia_uso_insert_own on ia_uso
  for insert
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- registra uma chamada de IA e recusa (exception) se o limite da janela já
-- foi atingido — chamado pelas Edge Functions antes de gastar com a OpenAI
-- ---------------------------------------------------------------------------
create function registrar_uso_ia(
  p_funcao text,
  p_limite int default 30,
  p_janela_minutos int default 60
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uso_atual int;
begin
  select count(*) into v_uso_atual
  from ia_uso
  where user_id = auth.uid()
    and funcao = p_funcao
    and criado_em >= now() - (p_janela_minutos || ' minutes')::interval;

  if v_uso_atual >= p_limite then
    raise exception 'limite de % chamadas de IA (%) por % minutos atingido — tente novamente mais tarde',
      p_limite, p_funcao, p_janela_minutos;
  end if;

  insert into ia_uso (user_id, funcao) values (auth.uid(), p_funcao);
end;
$$;

grant execute on function registrar_uso_ia(text, int, int) to authenticated;
