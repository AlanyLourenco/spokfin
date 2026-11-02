# Requisitos — Ambiente de desenvolvimento separado (projeto Supabase de dev)

> Esta spec começou como "stack local com Docker" e mudou de rumo depois do levantamento da máquina (ver §Alternativa descartada). O nome da pasta ficou.

## Contexto

Hoje só metade do app roda localmente. O Flutter sobe na máquina (`flutter run -d web-server --web-port=5000`), mas banco, Auth e Edge Functions existem **só** no projeto Supabase de produção, `lupelgzjyhvvgmdilmhj.supabase.co`. Não há separação entre desenvolver e usar.

As consequências já apareceram:

| Problema | Evidência |
|---|---|
| Todo teste escreve nos dados reais | O lançamento de teste da spec `0008` entrou na mesma base que os lançamentos de verdade |
| As 13 migrations sobem sem ensaio | São aplicadas à mão no SQL Editor, uma a uma. O único registro do que já rodou é a tabela em `supabase/migrations/README.md`, mantida manualmente. Ninguém nunca verificou se a sequência `0001`→`0013` roda limpa num banco vazio |
| Não dá para testar caso que não existe na base | O teste manual da spec `0010` não conseguiu verificar "Vencendo em breve" (nenhuma conta pendente), nem "Carregar mais" (poucos lançamentos), nem lançamento atrasado ou cancelado |
| O desenvolvimento para quando o projeto pausa | O plano gratuito suspendeu o projeto por inatividade em 01/09/2026, derrubando login, banco e Edge Functions ao mesmo tempo |

## Alternativa descartada: stack local com Docker

O caminho natural seria o Supabase CLI com Docker (`supabase start`), que dá banco offline e `supabase db reset`. Foi descartado pelo levantamento da máquina em 03/09/2026:

| Item | Estado |
|---|---|
| `winget` | v1.29.290 |
| **WSL2** | **não instalado** — exige administrador e reinicialização |
| Node | v24.18.0 |
| Disco livre | 362 GB |
| **RAM total** | **7,7 GB** |

Com 7,7 GB, Docker Desktop + WSL2 + os contêineres do Supabase disputariam memória com navegador, editor e o build do Flutter. Mesmo o stack enxuto (~1,5 GB, desligando Realtime/Storage/imgproxy/Studio) somado à reinicialização e à instalação de WSL2 não se pagou. **Decisão do usuário: um segundo projeto Supabase na nuvem, dedicado a desenvolvimento.**

O que se perde em relação ao local, e é aceito conscientemente: continua exigindo internet, e o projeto de dev também pausa por inatividade no plano gratuito.

## Objetivo

Desenvolver e testar contra um projeto Supabase **separado**, com dado de exemplo rico o bastante para exercitar todos os estados das telas, sem nunca mais escrever nos dados reais — e trocar entre dev e produção por configuração, sem editar código.

## Requisitos funcionais

- [ ] Existe um segundo projeto Supabase, de desenvolvimento, na conta do usuário (o plano gratuito permite 2 projetos ativos).
- [ ] As 13 migrations (`0001_init_schema` … `0013_empresa_telefone`) são aplicadas nele **do zero e em ordem**, num banco vazio — o que é, na prática, o primeiro ensaio completo da sequência. Qualquer erro encontrado aí é corrigido na migration, e o `supabase/migrations/README.md` registra o resultado.
- [ ] Existe um `supabase/seed.sql` que popula o projeto de dev com dado de exemplo cobrindo os estados que hoje não dá para testar: conta **pendente**, conta **atrasada**, conta **cancelada**, conta **paga**, lançamento com **NFC-e agendada**, cliente com débito, cliente sem débito, fornecedor com chave PIX, assinatura de MRR, e lançamentos suficientes para a paginação de 30 do Histórico disparar o "Carregar mais".
- [ ] O `seed.sql` é reexecutável: rodar de novo devolve o banco de dev ao mesmo estado conhecido, sem duplicar linha.
- [ ] Trocar entre dev e produção é uma ação de uma linha, documentada, **sem editar arquivo `.dart`** — `SUPABASE_URL`/`SUPABASE_ANON_KEY` continuam vindo de configuração e `main.dart` não muda.
- [ ] Fica visível em qual ambiente o app está rodando, para nunca haver dúvida se aquele lançamento foi para produção ou para dev.
- [ ] As 3 Edge Functions (`parse-lancamento`, `transcrever-audio`, `excluir-conta`) são implantadas também no projeto de dev, com suas secrets.
- [ ] Nenhum segredo novo entra no repositório — as chaves do projeto de dev ficam fora do git, como as de produção.
- [ ] `CLAUDE.md` passa a descrever o fluxo de dois ambientes como o padrão de desenvolvimento; `supabase/migrations/README.md` passa a registrar o estado **dos dois** projetos, deixando claro qual coluna é produção.
- [ ] O projeto de produção continua funcionando exatamente como hoje — esta spec não escreve nada nele.

## Fora de escopo

- **Stack local com Docker.** Descartado acima; se a máquina mudar, vira spec própria.
- **Migrar a produção para outro lugar.** `lupelgzjyhvvgmdilmhj` continua sendo a produção.
- **Automatizar o deploy de migrations** (`supabase db push`, CI aplicando SQL). O usuário continua aplicando à mão; o ganho aqui é que o dev vira o ensaio. Automatizar é outra spec.
- **CI rodando contra banco.** O `ci.yml` continua com `flutter analyze` + `flutter test`. Testar as regras que vivem em SQL é o item `N1'` do cronograma.
- **Copiar dados de produção para o dev.** O dev nasce do `seed.sql`, não de um dump — dado pessoal real não sai da produção (spec `0005`, LGPD).
- **Resolver o pause por inatividade.** Vale para os dois projetos no plano gratuito; sair disso é decisão comercial.

## Perguntas em aberto

1. **Como o app troca de ambiente?** Três formas, em ordem de preferência minha:
   - **`--dart-define`** no comando de run (`flutter run --dart-define=AMBIENTE=dev`), com o `.env` de cada ambiente escolhido em tempo de execução. Explícito no comando, impossível de esquecer.
   - **Dois arquivos** (`.env.dev` / `.env.prod`) e um script que copia o escolhido para `.env`. Simples, mas o estado fica invisível: dá para rodar sem saber qual está valendo.
   - **Um `.env` só**, editado à mão. É o que existe hoje, e é o que causa o risco.
2. **Como fica visível o ambiente na tela?** Uma faixa/etiqueta "DEV" no cabeçalho quando não é produção resolve, mas é UI nova — e a spec `0012` vai reescrever o visual logo depois. Vale fazer simples agora e revisitar lá.
3. **A `GEMINI_API_KEY` do dev é a mesma da produção?** A camada gratuita tem cota por chave (e o app já tem rate limit de 30/hora por usuário, spec `0007`). Usar a mesma chave faz o teste consumir a cota de produção. Recomendo criar uma segunda chave no Google AI Studio.
4. **O usuário de teste do dev é criado como?** O `seed.sql` não cria usuário de Auth de forma limpa (a tabela `auth.users` é do GoTrue). O caminho honesto é: você se cadastra uma vez pela própria tela de cadastro do app apontando para o dev, e o `seed.sql` pendura o dado de exemplo na empresa desse usuário. Precisa de confirmação porque muda a ordem dos passos.
