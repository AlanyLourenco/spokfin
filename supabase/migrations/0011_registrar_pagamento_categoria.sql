-- registrar_pagamento (0002) e marcar_lancamento_pendente (0007) foram
-- escritas antes de "categoria" existir em contas_pagar_receber (adicionada
-- só na 0008) e nunca foram atualizadas — trocar o status de um lançamento
-- perdia a categoria. Corrige recriando as duas funções com a mesma
-- assinatura, agora carregando a categoria nos dois sentidos.

create or replace function registrar_pagamento(p_conta_id uuid, p_data date default current_date)
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

  insert into transacoes (empresa_id, cliente_id, tipo, categoria, descricao, valor, data_transacao, nota_fiscal_status)
  values (
    v_conta.empresa_id,
    v_conta.cliente_id,
    case when v_conta.tipo = 'receber' then 'entrada' else 'saida' end,
    v_conta.categoria,
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

create or replace function marcar_lancamento_pendente(p_transacao_id uuid)
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
    empresa_id, cliente_id, tipo, categoria, descricao, valor, vencimento, status, nota_fiscal_status
  )
  values (
    v_transacao.empresa_id,
    v_transacao.cliente_id,
    case when v_transacao.tipo = 'entrada' then 'receber' else 'pagar' end,
    v_transacao.categoria,
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
