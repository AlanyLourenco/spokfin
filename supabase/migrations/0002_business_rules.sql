-- Fase 1: cálculo de saldo e status de pagamento no backend (não só na tela)
-- Funções e view abaixo rodam com os privilégios de quem chama — RLS continua valendo.

-- "atrasado" nunca fica gravado na coluna status: é sempre derivado do vencimento,
-- assim não precisa de job agendado pra manter a coluna em dia.
alter table contas_pagar_receber
  drop constraint contas_pagar_receber_status_check;

alter table contas_pagar_receber
  add constraint contas_pagar_receber_status_check
  check (status in ('pendente', 'pago', 'cancelado'));

create view contas_pagar_receber_vw
with (security_invoker = true)
as
select
  c.*,
  case
    when c.status = 'pendente' and c.vencimento < current_date then 'atrasado'
    else c.status
  end as status_efetivo
from contas_pagar_receber c;

grant select on contas_pagar_receber_vw to authenticated;

-- saldo da empresa: soma de entradas menos saídas já realizadas (transacoes)
create function calcular_saldo(p_empresa_id uuid)
returns numeric
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(sum(case when tipo = 'entrada' then valor else -valor end), 0)
  from transacoes
  where empresa_id = p_empresa_id;
$$;

grant execute on function calcular_saldo(uuid) to authenticated;

-- registrar pagamento/recebimento de uma conta: cria a transação correspondente
-- e fecha a conta, pra essas duas tabelas nunca ficarem inconsistentes entre si.
create function registrar_pagamento(p_conta_id uuid, p_data date default current_date)
returns transacoes
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_conta contas_pagar_receber;
  v_transacao transacoes;
begin
  select * into v_conta from contas_pagar_receber where id = p_conta_id;

  if not found then
    raise exception 'conta % não encontrada', p_conta_id;
  end if;

  if v_conta.status <> 'pendente' then
    raise exception 'conta % já está %', p_conta_id, v_conta.status;
  end if;

  insert into transacoes (empresa_id, cliente_id, tipo, descricao, valor, data_transacao, nota_fiscal_status)
  values (
    v_conta.empresa_id,
    v_conta.cliente_id,
    case when v_conta.tipo = 'receber' then 'entrada' else 'saida' end,
    v_conta.descricao,
    v_conta.valor,
    p_data,
    v_conta.nota_fiscal_status
  )
  returning * into v_transacao;

  update contas_pagar_receber
  set status = 'pago', transacao_id = v_transacao.id
  where id = p_conta_id;

  return v_transacao;
end;
$$;

grant execute on function registrar_pagamento(uuid, date) to authenticated;
