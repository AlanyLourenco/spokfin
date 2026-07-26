# Tarefas — Medidas de Economia no Uso de IA

- [x] `ia_service.dart`: nova exceção `LimiteIaExcedido`; `extrairLancamento`/`transcreverAudio` capturam `FunctionException` com `status == 429` e relançam como `LimiteIaExcedido`
- [x] `anotar_screen.dart`: `maxLength: 300` no campo de texto; validação de mínimo 3 caracteres antes de chamar a IA; `_extrairComRetry` relança `LimiteIaExcedido`; `_processar()` trata `LimiteIaExcedido` com SnackBar próprio
- [x] `falar_screen.dart`: piso de duração mínima (~1s / 32.000 bytes) antes de processar; `_processarComRetry` não chama `extrairLancamento` se a transcrição for trivial (<3 caracteres) e relança `LimiteIaExcedido`; `_concluir()` trata `LimiteIaExcedido` com SnackBar próprio
- [x] `supabase/functions/parse-lancamento/index.ts` (+ variante standalone): `generationConfig.maxOutputTokens = 512`
- [x] `supabase/functions/transcrever-audio/index.ts` (+ variante standalone): `generationConfig.maxOutputTokens = 1024`
- [x] `flutter analyze` limpo
- [x] `flutter test` passando
- [x] Commit + push
- [x] Avisar o usuário: reimplantar as duas Edge Functions (código mudou)
- [x] Testado manualmente no navegador — texto normal confirmado funcionando; texto curto demais/áudio curto demais ainda não testados explicitamente
- [x] Atualizar índice em `specs/README.md`
