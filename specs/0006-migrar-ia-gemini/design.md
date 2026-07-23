# Design — Migrar IA de OpenAI para Google Gemini

## Modelagem de dados
Nenhuma mudança.

## Backend

### Autenticação com o Gemini
API key via header `x-goog-api-key` (em vez de `Authorization: Bearer` da OpenAI), lida de `Deno.env.get("GEMINI_API_KEY")` — nova secret que o usuário precisa configurar no Supabase (Edge Functions → Secrets), no lugar de `OPENAI_API_KEY`.

Modelo usado nas duas funções: `gemini-2.0-flash` (suporta saída estruturada via `responseSchema` e entendimento nativo de áudio, dentro da cota gratuita do Google AI Studio). Fica como uma constante no topo de cada arquivo, fácil de trocar se o nome do modelo mudar no futuro.

### `parse-lancamento`
Troca a chamada `POST https://api.openai.com/v1/chat/completions` por:

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
headers: { "x-goog-api-key": GEMINI_API_KEY, "Content-Type": "application/json" }
body: {
  systemInstruction: { parts: [{ text: <mesmo texto de buildSystemPrompt()> }] },
  contents: [{ parts: [{ text: texto }] }],
  generationConfig: {
    responseMimeType: "application/json",
    responseSchema: <EXTRACTION_SCHEMA traduzido pro dialeto do Gemini>
  }
}
```

`EXTRACTION_SCHEMA` precisa ser traduzido pro dialeto de schema do Gemini (bem parecido, mas não idêntico ao JSON Schema usado com a OpenAI):
- `type` vira maiúsculo (`"OBJECT"`, `"STRING"`, `"NUMBER"`, `"BOOLEAN"`) em vez de minúsculo.
- Campos que podiam ser `null` (`cliente_nome`) usam `nullable: true` ao lado de `type: "STRING"`, em vez do formato `type: ["string", "null"]` que a OpenAI aceitava.
- Sem `additionalProperties` (o Gemini não tem esse campo no schema; não é necessário, ele já restringe às propriedades declaradas na prática).

Resposta do Gemini: `candidates[0].content.parts[0].text` contém a string JSON (igual ao `content` que já extraíamos da OpenAI) — a função devolve esse texto como o corpo da resposta, sem mudar nada no formato que `LancamentoExtraido.fromJson` espera do lado Flutter.

### `transcrever-audio`
Troca a chamada `POST https://api.openai.com/v1/audio/transcriptions` (multipart, Whisper) por uma chamada de texto+áudio ao Gemini, que entende áudio nativamente:

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
headers: { "x-goog-api-key": GEMINI_API_KEY, "Content-Type": "application/json" }
body: {
  contents: [{
    parts: [
      { text: "Transcreva o áudio a seguir para texto em português do Brasil. Responda só com a transcrição, sem comentários." },
      { inlineData: { mimeType: mime_type, data: audio_base64 } }
    ]
  }]
}
```

O `audio_base64` que já chega no corpo da requisição (vindo de `transcreverAudio()` no Flutter) é repassado direto pro `inlineData.data` do Gemini — não precisa decodificar/recodificar nada (o áudio gravado tem no máximo 40s a 16kHz mono, bem dentro do limite de tamanho do `inlineData`). Resposta: `candidates[0].content.parts[0].text` vira o `texto` no JSON de retorno — mesmo formato `{texto: "..."}` de antes.

### Rate limiting
`_shared/rate_limit.ts` não muda — continua chamando `registrar_uso_ia` antes de gastar a cota do provedor de IA, independente de qual for.

## Telas / UI
Nenhuma mudança — `ia_service.dart`, `anotar_screen.dart`, `falar_screen.dart` continuam chamando as mesmas duas Edge Functions com o mesmo contrato de entrada/saída.

## Decisões técnicas e alternativas consideradas
- **Manter as duas Edge Functions separadas (transcrever → extrair) em vez de unificar numa chamada só que já devolve o lançamento estruturado direto do áudio**: o Gemini permitiria isso (enviar áudio + pedir o `EXTRACTION_SCHEMA` direto), o que era tentador para simplificar. Mas isso mudaria o contrato que `falar_screen.dart` depende (`transcreverAudio` → `extrairLancamento` como duas etapas), arriscando mais regressão pra um ganho que não foi pedido agora. Troca de provedor "like-for-like" é mais seguro: zero mudança no lado Flutter, só a implementação interna das Edge Functions muda.
- **`gemini-2.0-flash` como modelo**: é o modelo estável mais recente com suporte a áudio nativo e saída estruturada dentro da cota gratuita do Google AI Studio no momento desta spec. Se o nome mudar (Google costuma iterar rápido em nomes de modelo), é uma troca de uma linha só (a constante `MODEL` no topo do arquivo).

## Riscos / dependências
- Precisa da secret `GEMINI_API_KEY` configurada no Supabase (Edge Functions → Secrets) — o usuário precisa gerar essa chave em [aistudio.google.com](https://aistudio.google.com/apikey) e configurar manualmente, e então reimplantar as duas funções com o código novo (mesmo processo manual já usado nesta sessão pra `excluir-conta`).
- Cota gratuita do Gemini tem limites de requisições por minuto/dia — se o app crescer bastante, pode ser necessário revisar (mas está muito acima do volume esperado de um MEI usando o app sozinho).
