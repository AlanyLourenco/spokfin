// Checagem de rate limit compartilhada pelas Edge Functions de IA
// (parse-lancamento, transcrever-audio) — chama a RPC `registrar_uso_ia`,
// que recusa (lança exceção) se o usuário já bateu o limite da janela.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export async function verificarLimiteIa(
  req: Request,
  funcao: "parse-lancamento" | "transcrever-audio",
): Promise<{ erro: string } | null> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );

  const { error } = await supabase.rpc("registrar_uso_ia", {
    p_funcao: funcao,
  });

  if (error) return { erro: error.message };
  return null;
}
