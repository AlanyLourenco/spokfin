# Design — Excluir/Arquivar Fornecedor

## Modelagem de dados
Nenhuma mudança de schema. Fornecedor é uma linha de `clientes` (`tipo = 'fornecedor'`), e a coluna `ativo boolean not null default true` já existe (migration `0009_arquivar_cliente.sql`) e já vale para essas linhas — arquivar um fornecedor é o mesmo `update clientes set ativo = false where id = ...` já usado para cliente.

## Backend
Nenhuma RPC nova. Duas queries de checagem (mesmas usadas em `FichaClienteScreen._excluirOuArquivar`):
- `select id from transacoes where cliente_id = :id limit 1`
- `select id from contas_pagar_receber where cliente_id = :id limit 1`

Se ambas vazias → `delete from clientes where id = :id`. Se alguma não-vazia → `update clientes set ativo = false where id = :id`.

RLS já cobre `clientes`/`transacoes`/`contas_pagar_receber` por `empresa_id` (via `is_member`), então nada muda ali.

## Telas / UI
`lib/clientes/ficha_fornecedor_screen.dart`:
- Adicionar `_excluirOuArquivar()` em `_FichaFornecedorScreenState`, copiando a lógica de `FichaClienteScreen._excluirOuArquivar` (linhas 181-247 daquele arquivo) mas usando `_fornecedor['id']` e `_nome` do fornecedor, e textos ajustados para "fornecedor" em vez de "cliente":
  - Diálogo com lançamentos: título "Fornecedor com lançamentos", corpo `'"$_nome" tem lançamentos vinculados, então não pode ser excluído — isso apagaria o histórico. Você pode arquivá-lo: ele some da lista de fornecedores, mas o histórico continua intacto.'`, botão "Arquivar fornecedor".
  - Diálogo sem lançamentos: título "Excluir fornecedor?", corpo `'"$_nome" não tem nenhum lançamento vinculado. Isso vai excluí-lo permanentemente.'`, botão "Excluir" (cor `AppColors.negative`, igual ao de cliente).
- Adicionar `IconButton(icon: Icons.delete_outline, tooltip: 'Excluir fornecedor')` na `AppBar.actions`, antes do `TextButton.icon` de Editar — mesma posição/ordem usada em `FichaClienteScreen`.
- Ao concluir exclusão/arquivamento, `Navigator.of(context).pop(true)` (mesmo padrão do cliente) para quem chamou (`ClientesScreen`) recarregar a lista.

Nenhuma tela nova — só uma adição pontual na ficha existente. `ClientesScreen` já filtra por `.eq('tipo', _aba).eq('ativo', true)` tanto na paginação quanto na busca (confirmado em `clientes_screen.dart:85` e `:161`), então fornecedores arquivados já somem da lista automaticamente assim que `ativo` vira `false` — nenhuma mudança necessária lá.

## Decisões técnicas e alternativas consideradas
- **Duplicar a lógica em vez de extrair um helper compartilhado**: `FichaClienteScreen` e `FichaFornecedorScreen` têm estruturas de estado diferentes (`_ItemHistorico`/`_FichaClienteDados` vs. nada disso no fornecedor) e o texto dos diálogos difere só no substantivo (cliente/fornecedor). Extrair um helper agora criaria uma abstração prematura para ~30 linhas quase-idênticas; se um terceiro "tipo" aparecer no futuro, aí sim vale extrair.

## Riscos / dependências
Nenhum. Não depende de migration nova nem de mudança de RLS.
