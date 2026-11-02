# Design — Correções de UI/UX apontadas na revisão

## Modelagem de dados / Backend

Nenhuma. Sem migration, sem RPC, sem Edge Function.

## O que foi feito

### E1/E4 — `lib/shared/seletor_periodo.dart` (novo)

`showDateRangePicker` sai das duas telas. No lugar, um bottom sheet com:

- **quatro atalhos** (Últimos 7 dias, Últimos 30 dias, Este mês, Mês passado), que resolvem quase toda pergunta num toque — o calendário do Material exigia rolar meses para achar as duas pontas;
- **dois campos `De`/`Até`** com `DataInputFormatter` e validação, para quem precisa de data exata.

A validação segue a convenção do projeto (sem `Form`/`GlobalKey`): checa no handler, `setState` numa string `_erro`, texto vermelho acima do botão.

### E4 — `DataInputFormatter` e `dataDeTexto` em `lib/shared/mascaras.dart`

`DataInputFormatter` põe as barras sozinho, no mesmo padrão dos formatters que já existiam. `dataDeTexto` converte `dd/mm/aaaa` em `DateTime` **conferindo campo a campo** — `DateTime(2023, 2, 31)` viraria 03/03 calado, e é exatamente esse tipo de erro que o modo de digitação antigo deixava passar. Ambos com teste em `test/mascaras_test.dart`.

### E2/E6 — `lib/shared/avatar_perfil.dart` (novo)

`AvatarPerfil` substitui o `IconButton(Icons.logout)` nas 4 telas de aba: círculo com iniciais ou ícone de pessoa, `Tooltip` e `Semantics(label: 'Abrir perfil')`, abrindo `PerfilScreen`. É o mesmo elemento que a Home já tinha — a inconsistência era das outras quatro.

O logout não foi enfraquecido: continua no Perfil. O que sai é o gatilho de uma ação destrutiva, sem confirmação, na barra principal.

### E3 — raio do indicador da navegação

De 14 para 10. Num item de ~44px de altura, 14 arredondava demais e o retângulo virava uma cápsula disforme.

### E5/E7/E8 — Ficha do Cliente

O histórico mostra 10 e ganha "Ver mais (N restantes)", que soma 10 a cada toque, com o contador zerado no `_recarregar`. Descrição vazia vira "Sem descrição" em itálico e `textMuted`, em vez de linha em branco.

## Decisões técnicas

- **D1 — atalhos antes dos campos.** A pergunta real do usuário é quase sempre "e nos últimos 30 dias?", não "e entre 12/03 e 27/08?". Pôr o caso comum a um toque e o exato logo abaixo é `progressive-disclosure`.
- **D2 — corte no cliente, não na consulta.** A Ficha calcula débito, total pago e interações por mês em cima da lista inteira; paginar na consulta obrigaria a mover esses agregados para o banco. O `take(N)` custa nada e resolve o que foi apontado — construir centenas de widgets de saída.
- **D3 — `Column` com `take` em vez de `ListView.builder`.** A skill recomenda `ListView.builder` para lista longa, mas esta lista está **dentro** de uma coluna rolável com gráfico e encarregados acima; um `ListView` aninhado exigiria `shrinkWrap` + `NeverScrollableScrollPhysics`, que constrói tudo do mesmo jeito. Com o corte em 10, o `take` resolve o problema real.
- **D4 — o avatar não busca as iniciais sozinho.** Recebe `iniciais` opcional e cai no ícone de pessoa quando não vem. Buscar o nome da empresa em 4 telas seria 4 consultas novas para um detalhe cosmético.

## Riscos

- O seletor novo perde a **visualização de calendário**: quem quiser ver em que dia da semana cai uma data não tem mais. Os atalhos cobrem o uso comum, mas se você sentir falta, dá para juntar um calendário compacto ao sheet.
- Os atalhos assumem que "Este mês" vai **até hoje**, não até o fim do mês. É o que faz sentido para um balanço, mas é uma escolha.
