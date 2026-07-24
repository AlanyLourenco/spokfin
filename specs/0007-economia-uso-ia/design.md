# Design — Medidas de Economia no Uso de IA

## Modelagem de dados
Nenhuma mudança.

## Backend

### `maxOutputTokens` nas duas Edge Functions
- `parse-lancamento`: `generationConfig.maxOutputTokens = 512` (a saída é um JSON pequeno de 8 campos — bem generoso, só um teto de segurança).
- `transcrever-audio`: `generationConfig.maxOutputTokens = 1024` (até 40s de fala ≈ 90-100 palavras ≈ bem menos que isso, com folga).

## Telas / UI

### `ia_service.dart` — distinguir "limite atingido" de outros erros
Nova exceção `LimiteIaExcedido implements Exception { mensagem }`. `extrairLancamento` e `transcreverAudio` capturam `FunctionException` (lançada pelo `supabase.functions.invoke` quando a resposta não é 2xx); se `e.status == 429`, relança como `LimiteIaExcedido` com a mensagem vinda do corpo da resposta (`{error: "..."}`, já devolvida pelas Edge Functions) ou uma mensagem genérica de fallback. Qualquer outro erro continua propagando normalmente (sem essa distinção).

### `anotar_screen.dart`
- `TextField` ganha `maxLength: 300` (Flutter já mostra o contador "x/300" sozinho).
- `_processar()`: antes de chamar `_extrairComRetry`, valida `texto.trim().length < 3` — se for o caso, mostra um `SnackBar` ("Digite pelo menos alguns caracteres.") e não chama nada.
- `_extrairComRetry`: passa a capturar `LimiteIaExcedido` separadamente e relançar (sem contar como uma das 2 tentativas nem cair no `catch` genérico que decide tentar de novo).
- `_processar()`: chamada a `_extrairComRetry` entra num `try/on LimiteIaExcedido catch (e)` — mostra `e.mensagem` num `SnackBar` e para ali, sem seguir pra tela de revisão.

### `falar_screen.dart`
- `_concluir()`: depois de obter `bytes = _audioBytes.takeBytes()`, adiciona um piso de duração mínima — a 16kHz mono 16-bit, 1 segundo de áudio = 32.000 bytes. Se `bytes.length < 32000`, mostra `SnackBar` ("Áudio muito curto — tente falar um pouco mais.") e não chama nenhuma IA (mesmo tratamento do caso `bytes.isEmpty` que já existe).
- `_processarComRetry`: depois de obter a transcrição (`texto = await transcreverAudio(...)`), se `texto.trim().length < 3`, retorna `null` direto (sem chamar `extrairLancamento`) — mesmo efeito do fallback "não consegui entender" de hoje, mas sem gastar a segunda chamada de IA à toa. Também captura e relança `LimiteIaExcedido` (mesmo padrão do Anotar).
- `_concluir()`: chamada a `_processarComRetry` entra num `try/on LimiteIaExcedido catch (e)` — mostra `e.mensagem` e não navega pra tela de revisão.

## Decisões técnicas e alternativas consideradas
- **`LimiteIaExcedido` como exceção própria, em vez de checar string de erro nas telas**: mais robusto que comparar texto de mensagem (que pode mudar) — usa o `status` HTTP (429) que já é o sinal estruturado que a Edge Function devolve.
- **300 caracteres no Anotar**: uma descrição de lançamento falada/digitada informalmente ("recebi 300 do João pelo serviço de ontem") raramente passa de 100 caracteres; 300 dá folga sem abrir margem pra colar textos grandes por engano.
- **Piso de 1s no áudio (32.000 bytes) em vez de checar só `bytes.isEmpty`**: um toque acidental no microfone gera alguns frames de áudio (não literalmente zero bytes) que ainda assim não tem conteúdo útil pra transcrever — o piso de duração pega esse caso que o `isEmpty` sozinho não pega.

## Riscos / dependências
Nenhum novo. Não depende de migration nem de redeploy de secret — só o código das duas Edge Functions (já vai precisar de reimplante, junto com qualquer ajuste futuro) e das telas Flutter.
