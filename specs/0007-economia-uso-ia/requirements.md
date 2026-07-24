# Requisitos — Medidas de Economia no Uso de IA

## Contexto
O app usa IA (Gemini, desde specs/0006) em dois pontos: "Anotar" (texto → lançamento estruturado) e "Falar" (áudio → texto → lançamento estruturado). Mesmo na camada gratuita, o uso é limitado (cota diária/por minuto do Google AI Studio), e o usuário quer garantir que nada no app deixe passar chamadas desnecessariamente caras ou excessivas.

**O que já existe:**
- Gravação de áudio já limitada a 40 segundos (`_limiteSegundos` em `falar_screen.dart`).
- Rate limiting geral: 30 chamadas de IA por hora, por função (`parse-lancamento`/`transcrever-audio` contam separado), por usuário — `registrar_uso_ia`, migration `0010_rate_limit_ia.sql`. Isso já impede um loop de bug ou abuso de disparar centenas de chamadas.

**O que falta:**
- O campo de texto do "Anotar rápido" não tem limite de caracteres — um usuário poderia colar um texto enorme (ou colar por engano o conteúdo errado), gastando muito mais tokens do que uma descrição de lançamento precisa.
- Nenhuma das duas telas valida um tamanho mínimo antes de chamar a IA — um texto vazio ou de 1-2 caracteres ainda dispara a chamada (e conta contra o limite de 30/hora) mesmo sabendo de antemão que não vai dar em nada útil.
- `_extrairComRetry`/`_processarComRetry` (Anotar e Falar) tentam de novo automaticamente 1 vez em **qualquer** erro — inclusive quando o erro já é "chamada de IA cara falhou" (então a segunda tentativa é uma segunda chamada cara). Não distingue "vale a pena tentar de novo" de "não adianta".
- As chamadas ao Gemini não têm um teto de tokens de saída (`maxOutputTokens`) — hoje confiamos só no formato do `responseSchema` pra manter a resposta pequena, sem um limite explícito de segurança.

## Objetivo
Reduzir o uso desnecessário de chamadas de IA em texto e áudio, sem prejudicar a experiência normal de uso (uma descrição de lançamento cabe folgadamente em qualquer um dos limites abaixo).

## Requisitos funcionais
- [ ] Campo de texto do "Anotar rápido" ganha um limite de caracteres (ex: 300) com contador visível, e o botão "Processar com IA" fica desabilitado acima desse limite (não deveria ser possível chegar lá, já que o campo trava em 300).
- [ ] As duas telas (Anotar, Falar) não chamam a IA se o texto/transcrição resultante for vazio ou trivialmente curto (ex: menos de 3 caracteres) — mostram um aviso local em vez de gastar uma chamada.
- [ ] O retry automático de `_extrairComRetry`/`_processarComRetry` só tenta de novo quando o erro **não** é um limite de taxa atingido (mensagem de `registrar_uso_ia`) — nesse caso, mostra o erro direto (algo como "Limite de uso de IA atingido, tente novamente mais tarde") sem gastar uma segunda chamada.
- [ ] As chamadas ao Gemini (`parse-lancamento`, `transcrever-audio`) ganham um `maxOutputTokens` explícito em `generationConfig`, como teto de segurança.

## Fora de escopo
- Não reduz o limite de 40s de gravação de áudio nem o limite de 30 chamadas/hora — ambos já existem e parecem adequados; mudar esses números é uma decisão separada, não incluída aqui a menos que peça.
- Não adiciona um painel de consumo/custo visível pro usuário (ex: "você usou X de Y chamadas hoje") — só as proteções técnicas, não uma UI de monitoramento.

## Perguntas em aberto
Nenhuma.
