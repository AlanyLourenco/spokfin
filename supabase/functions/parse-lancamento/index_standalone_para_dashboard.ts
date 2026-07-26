// Extrai um lançamento estruturado (tipo, valor, descrição, categoria, status,
// nota fiscal, cliente, data) a partir de texto solto em português, usando o
// Gemini (gemini-flash-latest, camada gratuita do Google AI Studio) — usado
// pelas telas "Anotar" e "Falar" do app.
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

const EXTRACTION_SCHEMA = {
  type: "OBJECT",
  properties: {
    tipo: { type: "STRING", enum: ["entrada", "saida"] },
    valor: { type: "NUMBER" },
    descricao: { type: "STRING" },
    categoria: { type: "STRING" },
    status: { type: "STRING", enum: ["pago", "pendente"] },
    quer_nota_fiscal: { type: "BOOLEAN" },
    cliente_nome: { type: "STRING", nullable: true },
    data: { type: "STRING" },
  },
  required: [
    "tipo",
    "valor",
    "descricao",
    "categoria",
    "status",
    "quer_nota_fiscal",
    "cliente_nome",
    "data",
  ],
};

function buildSystemPrompt(): string {
  const hoje = new Date().toISOString().split("T")[0];
  return `Você extrai lançamentos financeiros de microempreendedores (MEI) a partir de texto falado informalmente em português.

Hoje é ${hoje}.

Regras:
- "tipo": "entrada" se dinheiro recebido/ganho; "saida" se dinheiro pago/gasto.
- "valor": número positivo, sem símbolo de moeda.
- "descricao": breve, o que foi o lançamento.
- "categoria": uma palavra que categorize (ex: Serviço, Ferramentas, Consultoria, Aluguel, Venda, Impostos).
- "status": "pago" se o texto está no passado (ex: "recebi", "paguei" — já aconteceu); "pendente" se é algo futuro ou ainda não confirmado (ex: "vou receber", "preciso pagar").
- "quer_nota_fiscal": true somente se o texto disser explicitamente que o cliente quer/pediu nota fiscal; caso contrário false.
- "cliente_nome": nome da pessoa, empresa, loja ou estabelecimento que é a outra parte do lançamento — um cliente quando é uma entrada (ex: "recebi 300 do João" -> "João") ou um fornecedor/loja quando é uma saída (ex: "comprei 2000 no Peg Pag" -> "Peg Pag", "paguei a conta de luz na Enel" -> "Enel"); caso o texto mencione só um lugar genérico sem nome próprio (ex: "no mercado", "na loja"), retorne null.
- "data": data do lançamento no formato YYYY-MM-DD. Se nenhuma data for mencionada, use hoje (${hoje}). Se o texto mencionar um dia relativo ("ontem", "anteontem", "semana passada", etc.) ou uma data específica, calcule a data correta a partir de hoje.`;
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

  const limite = await verificarLimiteIa(req, "parse-lancamento");
  if (limite) {
    return new Response(JSON.stringify({ error: limite.erro }), {
      status: 429,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { texto } = await req.json();
  if (!texto || typeof texto !== "string") {
    return new Response(
      JSON.stringify({ error: "campo 'texto' é obrigatório" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "x-goog-api-key": Deno.env.get("GEMINI_API_KEY") ?? "",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: buildSystemPrompt() }] },
        contents: [{ parts: [{ text: texto }] }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: EXTRACTION_SCHEMA,
          maxOutputTokens: 512,
        },
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
  const content = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!content) {
    return new Response(
      JSON.stringify({ error: "IA não retornou um lançamento válido" }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(content, {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
