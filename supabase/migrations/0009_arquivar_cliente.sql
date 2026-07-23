-- Permite "arquivar" um cliente (inativar) em vez de excluir, quando ele já
-- tem lançamentos vinculados — a exclusão de verdade só é permitida no app
-- quando o cliente não tem nenhum lançamento vinculado.

alter table clientes
  add column ativo boolean not null default true;
