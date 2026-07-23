-- CNPJ e CPF são ambos opcionais no cadastro da empresa

alter table empresas
  alter column cnpj drop not null;

alter table empresas
  add column cpf text unique;
