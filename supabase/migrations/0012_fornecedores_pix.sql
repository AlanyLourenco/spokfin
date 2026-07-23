-- Fornecedores: em vez de uma tabela nova, "clientes" vira um cadastro de
-- contatos financeiros com um discriminador de tipo — evita duplicar a FK
-- (cliente_id) em transacoes/contas_pagar_receber e reaproveita toda a
-- estrutura de busca/paginação/RLS já existente.

alter table clientes
  add column tipo text not null default 'cliente'
    check (tipo in ('cliente', 'fornecedor')),
  add column chave_pix text,
  add column tipo_chave_pix text
    check (tipo_chave_pix in ('cpf_cnpj', 'email', 'telefone', 'aleatoria'));
