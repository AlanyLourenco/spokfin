# Tarefas — Migrar IA de OpenAI para Google Gemini

- [x] `supabase/functions/parse-lancamento/index.ts`: trocar chamada OpenAI por Gemini `generateContent`, schema traduzido pro dialeto do Gemini
- [x] `supabase/functions/transcrever-audio/index.ts`: trocar chamada Whisper por Gemini `generateContent` com áudio inline
- [x] `flutter analyze` limpo
- [x] `flutter test` passando (nenhum teste Dart quebrou, contrato Flutter intacto)
- [x] Commit + push
- [x] Avisar o usuário: gerar `GEMINI_API_KEY` em aistudio.google.com, configurar como secret no Supabase, reimplantar as duas Edge Functions
- [x] Testado manualmente no navegador — Anotar confirmado funcionando (modelo `gemini-flash-lite-latest`, após alguns ajustes de modelo pelo caminho); Falar ainda não testado explicitamente
- [x] Atualizar índice em `specs/README.md`
