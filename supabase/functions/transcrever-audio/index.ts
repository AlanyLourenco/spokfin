// Transcreve um áudio gravado no app (base64) para texto usando o Whisper
// (OpenAI) — usado pela tela "Falar".

import { verificarLimiteIa } from "../_shared/rate_limit.ts";

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

  const bytes = Uint8Array.from(atob(audio_base64), (c) => c.charCodeAt(0));
  const tipo = typeof mime_type === "string" ? mime_type : "audio/webm";
  const extensao = tipo.includes("wav") ? "wav" : "webm";

  const form = new FormData();
  form.append("file", new Blob([bytes], { type: tipo }), `audio.${extensao}`);
  form.append("model", "whisper-1");
  form.append("language", "pt");

  const whisperResponse = await fetch(
    "https://api.openai.com/v1/audio/transcriptions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      },
      body: form,
    },
  );

  if (!whisperResponse.ok) {
    const errorText = await whisperResponse.text();
    return new Response(JSON.stringify({ error: errorText }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const data = await whisperResponse.json();
  return new Response(JSON.stringify({ texto: data.text }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
