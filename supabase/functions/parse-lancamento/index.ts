// Extrai um lançamento estruturado (tipo, valor, descrição, categoria, status,
// nota fiscal, cliente, data) a partir de texto solto em português, usando
// GPT-4o mini (mais barato, suficiente para uma extração simples) — usado
// pelas telas "Anotar" e "Falar" do app.

import { verificarLimiteIa } from "../_shared/rate_limit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const EXTRACTION_SCHEMA = {
  type: "object",
  properties: {
    tipo: { type: "string", enum: ["entrada", "saida"] },
    valor: { type: "number" },
    descricao: { type: "string" },
    categoria: { type: "string" },
    status: { type: "string", enum: ["pago", "pendente"] },
    quer_nota_fiscal: { type: "boolean" },
    cliente_nome: { type: ["string", "null"] },
    data: { type: "string" },
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
  additionalProperties: false,
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
- "cliente_nome": nome da pessoa/empresa mencionada como cliente, se houver (ex: "recebi 300 do João" -> "João"); caso nenhum nome seja mencionado, retorne null.
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

  const openaiResponse = await fetch(
    "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: buildSystemPrompt() },
          { role: "user", content: texto },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "lancamento",
            schema: EXTRACTION_SCHEMA,
            strict: true,
          },
        },
      }),
    },
  );

  if (!openaiResponse.ok) {
    const errorText = await openaiResponse.text();
    return new Response(JSON.stringify({ error: errorText }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const data = await openaiResponse.json();
  const content = data.choices?.[0]?.message?.content;
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
