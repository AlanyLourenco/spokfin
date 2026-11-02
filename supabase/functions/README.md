# Edge Functions — spokfinRM

Deno/TypeScript, rodando no Supabase. Existem por dois motivos, e só por eles:

1. **Guardar segredo** — a `GEMINI_API_KEY` e a `SERVICE_ROLE_KEY` não podem chegar ao Flutter (é web: tudo que vai pro cliente é público).
2. **Guardar privilégio** — `auth.admin.deleteUser` não existe na chave anônima.

Nenhuma função confia em ID enviado pelo cliente: a identidade sempre vem do JWT verificado no header `Authorization`.

## Funções

| Função | O que faz | Chamada por |
|---|---|---|
| `parse-lancamento` | Texto solto em português → lançamento estruturado (tipo, valor, descrição, categoria, status, nota fiscal, cliente, data) via Gemini com `responseSchema` | `extrairLancamento()` em `lib/lancamentos/ia_service.dart` (telas Anotar e Falar) |
| `transcrever-audio` | Áudio (base64) → texto, via Gemini | `transcreverAudio()` em `lib/lancamentos/ia_service.dart` (tela Falar) |
| `excluir-conta` | Exclui `auth.users` do usuário autenticado; o resto cai por cascata de FK (LGPD, spec 0005) | `PerfilScreen` |

`_shared/rate_limit.ts` é usado pelas duas funções de IA: chama a RPC `registrar_uso_ia` e devolve **429** quando o usuário estoura o limite (30 chamadas/hora). O Flutter distingue esse 429 dos demais erros com a exceção `LimiteIaExcedido`, para **não** tentar de novo — um retry só gastaria outra chamada à toa.

## Secrets necessárias

| Secret | Usada por |
|---|---|
| `GEMINI_API_KEY` | `parse-lancamento`, `transcrever-audio` — gratuita no [Google AI Studio](https://aistudio.google.com/apikey) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `_shared/rate_limit.ts` (injetadas pelo Supabase) |
| `SUPABASE_SERVICE_ROLE_KEY` | `excluir-conta` (injetada pelo Supabase) |

Configurar em **Dashboard → Edge Functions → Secrets**.

## Por que existem os arquivos `index_standalone_para_dashboard.ts`

O deploy hoje é **manual, colando o código no editor do painel do Supabase** — e esse editor não suporta a pasta `_shared/` compartilhada entre funções. Então cada função de IA tem duas versões:

- `index.ts` — **a versão canônica do repositório**, com `import { verificarLimiteIa } from "../_shared/rate_limit.ts"`. É a que deve ser usada se algum dia o deploy passar a ser via CLI (`supabase functions deploy`).
- `index_standalone_para_dashboard.ts` — a mesma função com o rate limit inline, só para colar no painel.

> ⚠️ **As duas versões precisam ser alteradas juntas.** Ao mexer na lógica de uma função de IA, replique a mudança no arquivo standalone antes de commitar — senão o que está em produção e o que está no repo divergem silenciosamente. Migrar o deploy para a CLI do Supabase elimina essa duplicação e é o caminho recomendado quando houver oportunidade.

## Deploy (fluxo atual)

1. Dashboard → **Edge Functions** → selecionar a função (ou criar com o mesmo nome).
2. Colar o conteúdo de `index_standalone_para_dashboard.ts` (funções de IA) ou de `index.ts` (`excluir-conta`, que não usa `_shared/`).
3. **Deploy**, e testar pela tela correspondente no app.
