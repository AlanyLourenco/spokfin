-- Desfaz o pagamento de uma transação: recria como conta_pagar_receber
-- pendente e remove a transação. Contraparte de registrar_pagamento.

create function marcar_lancamento_pendente(p_transacao_id uuid)
returns contas_pagar_receber
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_transacao transacoes;
  v_conta contas_pagar_receber;
begin
  select * into v_transacao from transacoes where id = p_transacao_id;

  if not found then
    raise exception 'transação % não encontrada', p_transacao_id;
  end if;

  if v_transacao.assinatura_id is not null then
    raise exception 'não é possível desfazer o pagamento de uma mensalidade de assinatura por aqui';
  end if;

  insert into contas_pagar_receber (
    empresa_id, cliente_id, tipo, descricao, valor, vencimento, status, nota_fiscal_status
  )
  values (
    v_transacao.empresa_id,
    v_transacao.cliente_id,
    case when v_transacao.tipo = 'entrada' then 'receber' else 'pagar' end,
    v_transacao.descricao,
    v_transacao.valor,
    v_transacao.data_transacao,
    'pendente',
    v_transacao.nota_fiscal_status
  )
  returning * into v_conta;

  delete from transacoes where id = p_transacao_id;

  return v_conta;
end;
$$;

grant execute on function marcar_lancamento_pendente(uuid) to authenticated;
