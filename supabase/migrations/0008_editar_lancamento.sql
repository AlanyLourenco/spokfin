-- Permite editar um lançamento por completo, inclusive trocando o status
-- (pago <-> pendente), o que move a linha entre transacoes e
-- contas_pagar_receber.

alter table contas_pagar_receber
  add column categoria text;

create function atualizar_lancamento(
  p_id uuid,
  p_origem text,
  p_novo_status text,
  p_descricao text,
  p_categoria text,
  p_valor numeric,
  p_tipo text,
  p_cliente_id uuid,
  p_data date
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_nota_fiscal_status text;
begin
  if p_origem = 'transacao' then
    select empresa_id, nota_fiscal_status into v_empresa_id, v_nota_fiscal_status
    from transacoes where id = p_id;

    if not found then
      raise exception 'transação % não encontrada', p_id;
    end if;

    if p_novo_status = 'pago' then
      update transacoes
      set descricao = p_descricao,
          categoria = p_categoria,
          valor = p_valor,
          tipo = p_tipo,
          cliente_id = p_cliente_id,
          data_transacao = p_data
      where id = p_id;
    else
      insert into contas_pagar_receber (
        empresa_id, cliente_id, tipo, descricao, categoria, valor, vencimento, status, nota_fiscal_status
      )
      values (
        v_empresa_id,
        p_cliente_id,
        case when p_tipo = 'entrada' then 'receber' else 'pagar' end,
        p_descricao,
        p_categoria,
        p_valor,
        p_data,
        'pendente',
        v_nota_fiscal_status
      );
      delete from transacoes where id = p_id;
    end if;
  else
    select empresa_id, nota_fiscal_status into v_empresa_id, v_nota_fiscal_status
    from contas_pagar_receber where id = p_id;

    if not found then
      raise exception 'conta % não encontrada', p_id;
    end if;

    if p_novo_status = 'pendente' then
      update contas_pagar_receber
      set descricao = p_descricao,
          categoria = p_categoria,
          valor = p_valor,
          tipo = case when p_tipo = 'entrada' then 'receber' else 'pagar' end,
          cliente_id = p_cliente_id,
          vencimento = p_data
      where id = p_id;
    else
      insert into transacoes (
        empresa_id, cliente_id, tipo, categoria, descricao, valor, data_transacao, nota_fiscal_status
      )
      values (
        v_empresa_id,
        p_cliente_id,
        p_tipo,
        p_categoria,
        p_descricao,
        p_valor,
        p_data,
        v_nota_fiscal_status
      );
      delete from contas_pagar_receber where id = p_id;
    end if;
  end if;
end;
$$;

grant execute on function atualizar_lancamento(uuid, text, text, text, text, numeric, text, uuid, date) to authenticated;
