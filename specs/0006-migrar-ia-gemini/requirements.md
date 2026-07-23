# Requisitos — Migrar IA de OpenAI para Google Gemini

## Contexto
As duas Edge Functions que fazem o app entender lançamentos por texto/voz (`parse-lancamento` e `transcrever-audio`) usam a API da OpenAI (GPT-4o-mini e Whisper), que é paga por uso e exige conta com cartão + créditos pré-pagos. Testando o "Anotar rápido" ("comprei 600 de laranja no mercado"), o app caiu no fallback "Não consegui entender — preencha manualmente", porque a chamada à OpenAI falha sem uma `OPENAI_API_KEY` válida e com crédito configurada como secret no Supabase. O usuário quer usar um provedor de IA com camada gratuita, sem precisar configurar cobrança — decidiu por **Google Gemini** (Google AI Studio), que oferece chave de API grátis, sem cartão de crédito, com cota diária generosa nos modelos Flash.

## Objetivo
As duas funcionalidades de IA do app (entender texto digitado, transcrever e entender áudio falado) funcionam usando a API do Google Gemini em vez da OpenAI, sem exigir cartão de crédito ou conta paga, e sem nenhuma mudança perceptível pro usuário (mesma tela, mesmo fluxo, mesma qualidade de extração ou melhor).

## Requisitos funcionais
- [ ] `parse-lancamento` passa a chamar a API do Gemini (`generateContent`, modelo Flash) em vez da OpenAI, pedindo o mesmo formato de saída estruturada (tipo, valor, descrição, categoria, status, quer_nota_fiscal, cliente_nome, data) via `responseSchema`.
- [ ] `transcrever-audio` passa a chamar o Gemini (que entende áudio nativamente, enviado como `inlineData` em base64) pra transcrever o áudio gravado em português, em vez do Whisper da OpenAI.
- [ ] O contrato de entrada/saída das duas Edge Functions **não muda** — `ia_service.dart`, `anotar_screen.dart` e `falar_screen.dart` continuam funcionando sem nenhuma alteração no lado Flutter; só o que roda dentro das Edge Functions muda.
- [ ] Nova secret `GEMINI_API_KEY` no Supabase (no lugar de `OPENAI_API_KEY`, que deixa de ser necessária).
- [ ] Rate limiting (`_shared/rate_limit.ts`, RPC `registrar_uso_ia`) continua igual — não depende de qual provedor de IA é usado por trás.

## Fora de escopo
- Não unifica transcrição + extração numa chamada só (o Gemini permitiria enviar o áudio direto e já receber o lançamento estruturado, pulando a transcrição em texto como etapa separada) — mantém as duas Edge Functions e o fluxo atual (`transcreverAudio` → `extrairLancamento`) intactos, só trocando o provedor por trás de cada uma. Simplificar pra uma chamada só fica pra depois, se fizer sentido.
- Não mexe no rate limiting nem em nenhuma tela Flutter.

## Perguntas em aberto
Nenhuma — provedor (Google Gemini) já confirmado com o usuário.
