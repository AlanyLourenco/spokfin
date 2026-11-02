# spokfinRM

**Gestão financeira para microempreendedores, sem planilha e sem digitação manual.**

[![CI](https://github.com/AlanyLourenco/spokfin/actions/workflows/ci.yml/badge.svg)](https://github.com/AlanyLourenco/spokfin/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-web-02569B?logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Postgres%20%2B%20Auth%20%2B%20Edge%20Functions-3ECF8E?logo=supabase&logoColor=white)
![Gemini](https://img.shields.io/badge/Google%20Gemini-IA-4285F4?logo=googlegemini&logoColor=white)

## O problema

A maioria dos MEIs não registra o próprio fluxo de caixa porque isso significa abrir uma planilha e digitar campo por campo — descrição, categoria, cliente, data — toda vez que algo acontece. Na prática, isso simplesmente não é feito, e o dono do negócio perde visibilidade real sobre o próprio dinheiro.

## A solução

O usuário fala ou digita o que aconteceu, em português natural:

> "recebi 300 do João pela consultoria de ontem"
> "comprei 2000 no Peg Pag"

O spokfinRM transcreve (quando é áudio), extrai o lançamento estruturado inteiro — tipo, valor, categoria, status, cliente/fornecedor, data — via IA, e abre uma tela de confirmação já preenchida. O usuário revisa em segundos e ajusta só o que for preciso. Nenhum campo precisa ser digitado do zero no caminho comum.

## Funcionalidades

| Área | O que faz |
|---|---|
| **Lançamento por voz/texto** | Transcrição + extração estruturada via IA, com revisão humana antes de salvar — nunca grava nada sem confirmação |
| **Home** | Saldo consolidado, alertas de vencimento, atividade recente |
| **Histórico** | Filtro por período (mês atual/passado/personalizado), busca, exportação em PDF nomeado pelo período |
| **Balanço mensal** | Entradas x saídas, gastos por categoria (donut chart), gráfico que se adapta a dia ou mês conforme o período escolhido |
| **Clientes e Fornecedores** | Cadastro com CPF/CNPJ e chave PIX mascarados e validados (dígito verificador real), ficha com histórico e débito em aberto |
| **MRR / Assinaturas** | Cobrança recorrente mensal por cliente, com alerta de atraso |
| **Recibos em PDF** | Gerados no dispositivo do usuário — nada fica armazenado no servidor |
| **LGPD** | Termos de Uso/Privacidade, consentimento explícito no cadastro, exclusão de conta sob demanda |

## Engenharia

Esse é o eixo central do projeto — construído como estudo de caso de processo, não só de feature:

- **Spec-Driven Development real**: toda mudança nasce como `requirements.md` → `design.md` → `tasks.md` em [`specs/`](specs/) antes de qualquer código — decisões técnicas, trade-offs considerados e alternativas descartadas ficam registrados, não só o resultado final. Já são [9 specs completas](specs/README.md) documentando features de complexidade crescente.
- **Segurança por padrão**: Row Level Security em toda tabela via funções `security definer` (`is_member`/`is_owner`) — nenhuma query do cliente pode vazar dado de outra empresa, mesmo por engano. Segredos de API (Gemini) nunca chegam ao Flutter — vivem só em Edge Functions, que derivam a identidade do JWT verificado em vez de confiar em IDs enviados pelo cliente.
- **Design defensivo de custo de IA**: limite de caracteres/duração antes de sequer chamar a IA, detecção de "limite de uso atingido" pra não duplicar uma chamada já rejeitada, teto explícito de tokens de saída — a integração de IA foi projetada assumindo camada gratuita e uso real, não só o caminho feliz.
- **Testes automatizados** (`test/`) cobrindo a lógica pura testável: formatação monetária, máscaras e validação de CPF/CNPJ com dígito verificador de verdade, normalização de nomes (acentos/espaçamento) pra casar dados extraídos por IA com cadastros existentes, encoding WAV, parsing da extração de IA.
- **CI** rodando `flutter analyze` (zero warnings) + a suíte de testes a cada push — ver badge no topo.
- **Sem dependência por reflexo**: utilitários escritos à mão quando o ganho de uma lib não compensa o custo (encoder WAV, gráficos do dashboard, máscaras de input) — decisões e convenções completas em [`CLAUDE.md`](CLAUDE.md).

## Stack

**Flutter** (web-first) · **Supabase** (Postgres, Auth, Storage, Edge Functions) · **Google Gemini** (transcrição de áudio + extração estruturada, camada gratuita) · **Deno/TypeScript** (Edge Functions)

## Rodando localmente

```bash
flutter pub get
cp .env.example .env   # preencher SUPABASE_URL e SUPABASE_ANON_KEY
flutter run -d web-server --web-port=5000 --web-hostname=localhost
```

As migrations em [`supabase/migrations/`](supabase/migrations/) precisam ser aplicadas, em ordem, no SQL Editor do projeto Supabase — o [registro do que já foi aplicado e o mapa do schema](supabase/migrations/README.md) ficam ali. As Edge Functions em [`supabase/functions/`](supabase/functions/) precisam de uma secret `GEMINI_API_KEY` (gratuita via [Google AI Studio](https://aistudio.google.com/apikey)); [como implantar](supabase/functions/README.md).

## Onde está cada coisa

| Documento | Assunto |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Arquitetura, convenções de código e fluxo de desenvolvimento |
| [`PRODUCT.md`](PRODUCT.md) | Usuário-alvo, propósito e princípios de produto |
| [`DESIGN.md`](DESIGN.md) | Identidade visual: tokens, tipografia, motion |
| [`specs/`](specs/) | Specs por feature, histórias de usuário e roadmap |
| [`supabase/migrations/README.md`](supabase/migrations/README.md) | Estado do banco e mapa de tabelas/views/RPCs |
| [`supabase/functions/README.md`](supabase/functions/README.md) | Edge Functions: o que fazem, secrets, deploy |
