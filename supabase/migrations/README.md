# Migrations — spokfinRM

Não há runner automatizado neste fluxo: **cada arquivo `.sql` é colado e executado manualmente no SQL Editor do projeto Supabase**, em ordem numérica. Este arquivo é o único registro do que já foi aplicado — se ele estiver desatualizado, ninguém consegue saber o estado real do banco.

## Como aplicar uma migration

1. Abrir o projeto no [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor** → **New query**.
2. Colar o conteúdo do arquivo **inteiro** (os arquivos são idempotentes só quando dizem `if not exists` / `create or replace` — não assuma que rodar duas vezes é seguro).
3. Executar e conferir que não houve erro.
4. **Marcar `✅` na tabela abaixo, no mesmo commit em que a migration é criada ou aplicada.**

## Regras

- Numeração sequencial de 4 dígitos, sem buracos e sem reaproveitar número: `NNNN_descricao_curta.sql`.
- Uma migration nunca é editada depois de aplicada em produção — corrija com uma migration nova (foi o caso da `0011`, que conserta funções da `0002`/`0007`).
- Toda tabela nova precisa de `empresa_id` + políticas de RLS via `is_member`/`is_owner` desde a primeira versão. Não existe tabela sem RLS neste projeto.
- Regra de negócio que o app depende (saldo, transição pago↔pendente, MRR) vive em função SQL, não só na tela — assim o cálculo não diverge entre telas.

## Status

| # | Arquivo | O que faz | Aplicada? |
|---|---------|-----------|-----------|
| 0001 | `0001_init_schema.sql` | Schema inicial: `empresas`, `clientes`, `transacoes`, `contas_pagar_receber` + RLS | ✅ |
| 0002 | `0002_business_rules.sql` | View `contas_pagar_receber_vw` (deriva `status_efetivo`/"atrasado" sem job agendado), `calcular_saldo`, `registrar_pagamento` | ✅ |
| 0003 | `0003_membros_e_perfis.sql` | `membros` + perfis (dono/funcionário/contador), helpers `is_member`/`is_owner`, `handle_new_user`/`handle_new_empresa`, `convidar_membro` | ✅ |
| 0004 | `0004_empresa_documento_opcional.sql` | CNPJ e CPF passam a ser opcionais na empresa (MEI não é exigência) | ✅ |
| 0005 | `0005_assinaturas.sql` | MRR: `assinaturas`, view `assinaturas_com_status`, `calcular_mrr`, `registrar_pagamento_assinatura` (spec 0001) | ✅ |
| 0006 | `0006_encarregados.sql` | `encarregados` (contatos vinculados a um cliente) (spec 0002) | ✅ |
| 0007 | `0007_marcar_lancamento_pendente.sql` | `marcar_lancamento_pendente` — desfaz um pagamento (contraparte de `registrar_pagamento`) | ✅ |
| 0008 | `0008_editar_lancamento.sql` | `contas_pagar_receber.categoria` + `atualizar_lancamento` (edição completa, inclusive troca de status entre as duas tabelas) | ✅ |
| 0009 | `0009_arquivar_cliente.sql` | `clientes.ativo` — arquivar em vez de excluir quando há lançamentos vinculados (spec 0003) | ✅ |
| 0010 | `0010_rate_limit_ia.sql` | `ia_uso` + `registrar_uso_ia` — 30 chamadas de IA/hora por usuário | ✅ |
| 0011 | `0011_registrar_pagamento_categoria.sql` | Corrige `registrar_pagamento`/`marcar_lancamento_pendente` para preservar `categoria` na transição pago↔pendente | ✅ (aplicada em 03/09/2026 — ver nota) |
| 0012 | `0012_fornecedores_pix.sql` | `clientes.tipo` (`cliente`/`fornecedor`) + `chave_pix`/`tipo_chave_pix` | ✅ |
| 0013 | `0013_empresa_telefone.sql` | `empresas.telefone`, usado na tela de Perfil (spec 0005) | ✅ |

> ✅ **Verificado no banco em 01–03/09/2026**, consultando `information_schema` e `pg_proc` no SQL Editor. As 13 migrations estão aplicadas. A partir daqui, esta tabela é atualizada no mesmo commit da migration.

### Nota: a 0011 ficou 2 anos sem ser aplicada

A verificação de 01/09/2026 encontrou `registrar_pagamento` e `marcar_lancamento_pendente` no banco **na versão antiga** (a de 0002/0007) — `prosrc` sem nenhuma menção a `categoria` nas duas. O arquivo da migration existia no repositório desde sempre; nunca tinha sido colado no SQL Editor, e nenhum documento registrava isso.

**Efeito enquanto durou:** marcar um lançamento como pago e depois voltá-lo para pendente (ou o contrário) **apagava a categoria**. A linha migrava entre `transacoes` e `contas_pagar_receber` sem carregar `categoria`, e o lançamento reaparecia sem categoria no Histórico, na Home e no donut de gastos por categoria do Balanço.

**Aplicada em 03/09/2026** (as duas funções recriadas via `create or replace`), e confirmada com:

```sql
select proname, prosrc like '%categoria%' as carrega_categoria
from pg_proc
where proname in ('registrar_pagamento','marcar_lancamento_pendente');
-- marcar_lancamento_pendente | true
-- registrar_pagamento        | true
```

⚠️ **Dado histórico não foi recuperado:** lançamentos que perderam a categoria antes disso continuam sem categoria. A migration só conserta o comportamento daqui pra frente — se houver lançamentos antigos sem categoria, precisam ser reeditados à mão no app.

**A lição, para as próximas:** escrever a migration e aplicá-la são duas coisas, e só a primeira deixa rastro no git. É por isso que a coluna "Aplicada?" desta tabela existe e precisa ser preenchida no mesmo commit.

## Se o SQL Editor não abrir

O projeto pode estar **pausado** — é o comportamento do plano gratuito do Supabase depois de um período sem uso. Os dados continuam íntegros; basta **Resume project** no dashboard. Enquanto estiver pausado não há banco, Auth nem Edge Functions, ou seja, o app não abre e nada aqui pode ser conferido.

## Mapa do schema

**Tabelas** — todas isoladas por `empresa_id` via RLS:

| Tabela | Papel |
|---|---|
| `empresas` | A "conta". Uma por dono (`owner_id` → `auth.users`). CNPJ/CPF opcionais. |
| `membros` | Perfis de acesso à empresa (dono, funcionário, contador). Backend pronto; a tela de Equipe ainda não existe (item F1 do roadmap). |
| `clientes` | Cadastro de **contatos financeiros**: `tipo = 'cliente'` ou `'fornecedor'`. Fornecedor não tem tabela própria — ver `CLAUDE.md`. |
| `encarregados` | Pessoas de contato vinculadas a um cliente. |
| `transacoes` | Lançamentos **já pagos** (entrada/saída). |
| `contas_pagar_receber` | Lançamentos **pendentes** (a pagar/a receber). Um lançamento migra entre esta tabela e `transacoes` quando muda de status. |
| `assinaturas` | Cobrança recorrente mensal de um cliente (MRR). |
| `ia_uso` | Log de chamadas de IA por usuário, para o rate limit. |

**Views** — sempre prefira a view à tabela crua quando existir:

| View | Por que existe |
|---|---|
| `contas_pagar_receber_vw` | Deriva `status_efetivo` (`pendente`/`atrasado`/`pago`) a partir do vencimento. "Atrasado" nunca é gravado em coluna, então não precisa de job agendado. |
| `assinaturas_com_status` | Mesma ideia para assinaturas (em dia / atrasada). |

**Funções chamadas pelo app (RPC):**

| Função | Uso |
|---|---|
| `calcular_saldo` | Saldo consolidado da empresa. |
| `calcular_mrr` | Receita recorrente mensal. |
| `registrar_pagamento` | Conta pendente → transação paga. **Retorna a linha resultante**, para o app atualizar o estado local sem recarregar tudo. |
| `marcar_lancamento_pendente` | Transação paga → conta pendente. Também retorna a linha. |
| `atualizar_lancamento` | Edição completa de um lançamento, inclusive troca de status (move a linha entre as duas tabelas). |
| `registrar_pagamento_assinatura` | Gera/quita a cobrança do mês de uma assinatura. |
| `registrar_uso_ia` | Checa e registra o rate limit; devolve 429 para as Edge Functions quando estourado. |

**Funções internas (não chamar do app):** `is_member`, `is_owner` (helpers `security definer` usados nas políticas de RLS), `handle_new_user`, `handle_new_empresa` (triggers), `convidar_membro`.
