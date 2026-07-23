# Requisitos — Excluir/Arquivar Fornecedor

## Contexto
Clientes já têm a opção de excluir (ou arquivar, se tiverem lançamentos vinculados) na Ficha do Cliente. Fornecedores foram modelados como linhas de `clientes` com `tipo = 'fornecedor'` e reaproveitam a mesma coluna `ativo`, mas a Ficha do Fornecedor nunca ganhou o botão equivalente — hoje não existe forma de remover um fornecedor cadastrado por engano ou que parou de ser usado.

## Objetivo
O usuário consegue excluir um fornecedor sem lançamentos vinculados, ou arquivá-lo (deixa de aparecer na lista, histórico preservado) quando já existem lançamentos vinculados a ele — exatamente como já funciona para clientes.

## Requisitos funcionais
- [ ] A Ficha do Fornecedor (`FichaFornecedorScreen`) ganha um ícone de excluir na AppBar, igual ao da Ficha do Cliente.
- [ ] Ao tocar em excluir, o sistema verifica se o fornecedor tem `transacoes` ou `contas_pagar_receber` vinculados (`cliente_id`).
- [ ] Se **não** tiver nenhum lançamento vinculado: mostra diálogo de confirmação e, ao confirmar, executa `delete` da linha em `clientes`.
- [ ] Se **tiver** lançamentos vinculados: mostra diálogo explicando que não pode ser excluído (apagaria o histórico) e oferece "Arquivar fornecedor", que faz `update ativo = false`.
- [ ] Depois de excluir/arquivar, a tela fecha e devolve `true` para quem chamou, para a lista de Clientes/Fornecedores recarregar (mesmo padrão do `Navigator.pop(true)` usado em `FichaClienteScreen`).
- [ ] A lista de Fornecedores (aba Fornecedores em `ClientesScreen`) já filtra por `ativo = true` (reaproveita o filtro existente usado para Clientes) — nenhuma mudança de query esperada aqui, só confirmar que o mesmo `.eq('ativo', true)` cobre fornecedores.

## Fora de escopo
- Não adiciona um fluxo de "reativar" fornecedor arquivado (mesma limitação que já existe hoje para clientes arquivados).
- Não mexe na lógica de exclusão/arquivamento de Cliente já existente — só espelha o mesmo comportamento para Fornecedor.
- Nenhuma migration nova: a coluna `ativo` já existe na tabela `clientes` (migration 0009) e já se aplica a fornecedores, já que é a mesma tabela.

## Perguntas em aberto
Nenhuma — comportamento é uma cópia direta do que já existe para Cliente.
