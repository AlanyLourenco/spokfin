// Transcreve um áudio gravado no app (base64) para texto usando o Gemini
// (gemini-flash-latest, que entende áudio nativamente, camada gratuita do
// Google AI Studio) — usado pela tela "Falar".
//
// Versão autocontida (sem import de ../_shared/rate_limit.ts) — só pra colar
// no editor do painel do Supabase, que não suporta pastas compartilhadas
// entre funções. O arquivo "de verdade" do repo (index.ts, ao lado deste)
// continua usando o import compartilhado — é o que deve ser usado se algum
// dia passar a implantar via CLI do Supabase.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const MODEL = "gemini-flash-latest";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function verificarLimiteIa(
  req: Request,
  funcao: "parse-lancamento" | "transcrever-audio",
): Promise<{ erro: string } | null> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: { Authorization: req.headers.get("Authorization") ?? "" },
      },
    },
  );

  const { error } = await supabase.rpc("registrar_uso_ia", {
    p_funcao: funcao,
  });

  if (error) return { erro: error.message };
  return null;
}

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
        generationConfig: { maxOutputTokens: 1024 },
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
