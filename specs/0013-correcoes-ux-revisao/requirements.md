# Requisitos — Correções de UI/UX apontadas na revisão

## Contexto

Depois da Etapa 1 da spec `0012`, o usuário abriu o app, testou e anotou cinco problemas em `erros.pdf` (04/09/2026). Os screenshots são do app real, já com a paleta nova. A auditoria desses cinco com a skill `ui-ux-pro-max` revelou mais três, sendo um deles grave.

| # | Apontado pelo usuário | Onde |
|---|---|---|
| E1 | "jeito péssimo de selecionar período intervalado" | `showDateRangePicker` do Material, em Balanço e Histórico |
| E2 | "na barra principal fica algo para logout, isso não existe, deveria ser uma bolinha que direciona para o perfil" | Balanço, Clientes, Histórico, MRR |
| E3 | "arredondamento de borda errado" | indicador da navegação flutuante criada na Etapa 1 da `0012` |
| E4 | "sem filtro para modelar entrada de data" | modo de digitação do seletor de período |
| E5 | "o app não tem limite de exibição... tem que ter uma certa quantidade e um 'ver mais'" | histórico da Ficha do Cliente |

Encontrados na auditoria:

| # | Achado |
|---|---|
| E6 | O logout disparava `supabase.auth.signOut` **no primeiro toque, sem confirmação** — ação destrutiva, em 4 telas, ao lado de ações comuns. Viola `confirmation-dialogs` e `destructive-nav-separation` |
| E7 | O histórico da Ficha construía **todos** os widgets de uma vez num `Column`; a spec `0010` ainda tirou o limite implícito da consulta. Viola `virtualize-lists` |
| E8 | Lançamento com descrição vazia renderiza uma **linha em branco** — visível no próprio screenshot do usuário |

## Objetivo

Os oito problemas corrigidos, sem perder funcionalidade e sem inventar tela nova.

## Requisitos funcionais

- [x] Selecionar período é rápido para o caso comum e exato quando preciso, sem calendário de tela cheia (E1)
- [x] A digitação de data tem máscara `dd/mm/aaaa` e validação real (E4)
- [x] A barra superior das telas de aba tem a bolinha de perfil, não o logout (E2, E6)
- [x] O logout continua existindo no Perfil, que é onde se procura por ele (E6)
- [x] O indicador da navegação tem raio proporcional à altura do item (E3)
- [x] Listas longas mostram um bloco e oferecem "ver mais" (E5, E7)
- [x] Descrição vazia mostra um marcador, não uma linha em branco (E8)
- [x] `flutter analyze` limpo e `flutter test` passando

## Fora de escopo

- Trocar o `showDatePicker` de data única (usado em outras telas) — só o de intervalo foi apontado.
- Paginação server-side na Ficha do Cliente: o corte é no cliente. Um cliente com milhares de lançamentos ainda carrega tudo do Supabase — vira spec própria se aparecer.
- Confirmação de logout no Perfil: lá ele é explícito e esperado.
