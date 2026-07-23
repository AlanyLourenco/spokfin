// Transcreve um áudio gravado no app (base64) para texto usando o Gemini
// (gemini-2.0-flash, que entende áudio nativamente, camada gratuita do
// Google AI Studio) — usado pela tela "Falar".

import { verificarLimiteIa } from "../_shared/rate_limit.ts";

const MODEL = "gemini-2.0-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  const limite = await verificarLimiteIa(req, "transcrever-audio");
  if (limite) {
    return new Response(JSON.stringify({ error: limite.erro }), {
      status: 429,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { audio_base64, mime_type } = await req.json();
  if (!audio_base64 || typeof audio_base64 !== "string") {
    return new Response(
      JSON.stringify({ error: "campo 'audio_base64' é obrigatório" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const tipo = typeof mime_type === "string" ? mime_type : "audio/webm";

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "x-goog-api-key": Deno.env.get("GEMINI_API_KEY") ?? "",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text:
                  "Transcreva o áudio a seguir para texto em português do " +
                  "Brasil. Responda só com a transcrição, sem comentários " +
                  "adicionais.",
              },
              { inlineData: { mimeType: tipo, data: audio_base64 } },
            ],
          },
        ],
      }),
    },
  );

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return new Response(JSON.stringify({ error: errorText }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const data = await geminiResponse.json();
  const texto = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!texto) {
    return new Response(
      JSON.stringify({ error: "IA não retornou uma transcrição válida" }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(JSON.stringify({ texto }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
