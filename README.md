# spokfinRM

Gestão financeira para Microempreendedores Individuais (MEI), com lançamentos por voz e texto processados por IA — sem planilha, sem digitação manual de cada item.

O usuário fala ou digita o que aconteceu ("recebi 300 do João pela consultoria de ontem", "comprei 2000 no Peg Pag") e o app extrai automaticamente tipo, valor, categoria, status e cliente/fornecedor, pré-preenchendo uma tela de confirmação — o usuário só revisa e ajusta o que for preciso.

## Funcionalidades

- **Lançamento por voz e texto (IA)** — transcrição e extração estruturada via Google Gemini, com confirmação humana antes de salvar.
- **Home** — saldo, alertas de vencimento, lançamentos recentes.
- **Histórico** — filtros por período (mês atual, mês passado, período personalizado), busca, exportação em PDF.
- **Balanço mensal** — entradas x saídas, gastos por categoria (donut chart), gráfico diário/mensal conforme o período escolhido.
- **Clientes e Fornecedores** — cadastro com CPF/CNPJ e chave PIX (com máscara e validação de dígito verificador), ficha com histórico e débito em aberto, encarregados por cliente.
- **MRR / Assinaturas** — cobrança recorrente mensal por cliente.
- **Recibos em PDF** — gerados no próprio dispositivo, sem persistência no servidor.
- **Perfil e LGPD** — Termos de Uso/Política de Privacidade, consentimento explícito no cadastro, exclusão de conta e dados sob demanda.

## Stack

- **Flutter** (web-first) + **Supabase** (Postgres, Auth, Storage, Edge Functions).
- **Google Gemini** (camada gratuita) para transcrição de áudio e extração de lançamentos estruturados a partir de texto livre.
- Segurança de dados via **Row Level Security** em todas as tabelas (funções `security definer` `is_member`/`is_owner`) — cada empresa só acessa os próprios dados.
- Segredos (chaves de API) nunca chegam ao cliente — vivem só nas Edge Functions.

## Engenharia

- **Spec-Driven Development**: toda feature nova nasce como `specs/NNNN-nome/requirements.md` → `design.md` → `tasks.md` antes de qualquer linha de código — ver [`specs/`](specs/) para o histórico completo de decisões técnicas e de produto.
- **Testes automatizados** (`test/`) cobrindo a lógica pura (formatação de moeda, máscaras e validação de CPF/CNPJ com dígito verificador real, encoding WAV, parsing da extração de IA).
- **CI** (`.github/workflows/ci.yml`) rodando `flutter analyze` + `flutter test` a cada push.
- Utilitários escritos à mão em vez de dependências pesadas quando o ganho não compensa o custo (encoder WAV, gráficos do dashboard, máscaras de input) — ver [`CLAUDE.md`](CLAUDE.md) para as convenções completas do projeto.

## Rodando localmente

```bash
flutter pub get
cp .env.example .env   # preencher SUPABASE_URL e SUPABASE_ANON_KEY
flutter run -d web-server --web-port=5000 --web-hostname=localhost
```

As migrations em [`supabase/migrations/`](supabase/migrations/) precisam ser aplicadas, em ordem, no SQL Editor do projeto Supabase. As Edge Functions em [`supabase/functions/`](supabase/functions/) precisam de uma secret `GEMINI_API_KEY` (gratuita via [Google AI Studio](https://aistudio.google.com/apikey)).
