# Requisitos — Organização do código: modelo e componentes de lançamento unificados

## Contexto

Com 9 specs implementadas, o app chegou a ~10.200 linhas de Dart com `flutter analyze` limpo e 44 testes passando — a saúde técnica está boa, mas a **organização** começou a se degradar de um jeito específico e mensurável: quatro telas diferentes reimplementaram, cada uma por conta própria, o mesmo conceito de "um lançamento na lista".

Evidência levantada no código atual:

| Duplicação | Onde |
|---|---|
| Modelo de linha de lançamento **byte a byte idêntico**, só o nome da classe muda | `_LancamentoResumo` (`home_screen.dart:16`) e `_Item` (`historico_screen.dart:31`) — 13 campos iguais, na mesma ordem |
| Variantes reduzidas do mesmo modelo | `_LancamentoMes` (`balanco_screen.dart:837`), `_ItemHistorico` (`ficha_cliente_screen.dart:610`) |
| Modelo canônico que já existe e **não é usado por nenhuma dessas telas** | `LancamentoDetalhado` (`lib/lancamentos/lancamento_detalhado.dart`) |
| Query "transações + `contas_pagar_receber_vw` + resolver nome do cliente + mesclar e ordenar por data" | `home_screen.dart:109-198` e `historico_screen.dart:144-215` — ~60 linhas quase idênticas |
| Tradução de status para rótulo (`'atrasado'` → `'Atrasado'`, senão `'Pendente'`) | `home_screen.dart:168`, `historico_screen.dart:208`, `detalhes_lancamento_screen.dart:478`, `mrr_screen.dart:330` |
| Pílula "NFC-e agendada" (contêiner + borda + ícone + texto, mesmos valores) | `home_screen.dart:707`, `historico_screen.dart:745` |
| Tile de lançamento (mesma estrutura: descrição, subtítulo, pílula de NF, valor com sinal e cor) | `_LancamentoTile` (home), `_ItemTile` (histórico), `_LancamentoMesTile` (balanço), lista da ficha do cliente |

O custo disso não é estético. É que **uma mudança de comportamento no lançamento hoje precisa ser feita de 2 a 4 vezes**, e já falhou por esse motivo pelo menos uma vez no projeto (a migration `0011` existe justamente porque duas funções que tratam do mesmo lançamento foram atualizadas em lugares diferentes e uma ficou para trás). Um "atrasado" que passe a ter regra nova, um campo novo vindo do banco, ou um ajuste no visual da lista, hoje têm chance real de sair inconsistente entre Home e Histórico.

Isso também empurra os arquivos para um tamanho em que fica difícil trabalhar: `balanco_screen.dart` (1.062 linhas), `detalhes_lancamento_screen.dart` (1.024), `historico_screen.dart` (768) e `home_screen.dart` (736) concentram 35% do código do app.

## Objetivo

Um lançamento tem **um** modelo, **uma** função que o carrega do Supabase e **um** componente que o desenha em lista — de modo que mudar o comportamento do lançamento signifique editar um arquivo, não quatro. Sem nenhuma mudança visível para o usuário.

## Requisitos funcionais

- [ ] `LancamentoDetalhado` passa a ser o único modelo de linha de lançamento do app; `_LancamentoResumo`, `_Item`, `_LancamentoMes` e `_ItemHistorico` deixam de existir.
- [ ] A tradução de status para rótulo (`Pago`/`Pendente`/`Atrasado`) e a cor/ícone correspondentes existem em um lugar só, e as 4 telas consomem dali.
- [ ] A leitura "transações + contas pendentes mescladas, com nome de cliente resolvido" vira uma função única, com parâmetros para as diferenças reais entre as telas (limite, período, filtro por cliente, incluir ou não pagos).
- [ ] Existe um componente único de tile de lançamento em `lib/shared/` (ou `lib/lancamentos/`), com as variações atuais expressas como parâmetros — não como cópias.
- [ ] A pílula "NFC-e agendada"/"NFC-e emitida" vira um componente reutilizável.
- [ ] O comportamento visível permanece **idêntico**: mesmas telas, mesmos textos, mesmas cores, mesma paginação, mesmos filtros. Esta spec não muda nada que o usuário perceba.
- [ ] A lógica pura extraída (mapeamento de linha do Supabase → `LancamentoDetalhado`, rótulo de status) ganha testes em `test/`, conforme a convenção do projeto.
- [ ] `flutter analyze` reporta "No issues found!" e `flutter test` passa ao final.
- [ ] `CLAUDE.md` passa a registrar o modelo/repositório/componente unificados como a convenção a seguir em tela nova.

## Fora de escopo

- **Introduzir gerenciamento de estado** (Provider/Riverpod/Bloc) ou qualquer dependência nova. A decisão de `StatefulWidget` + `setState` + `lancamentos_bus.dart` continua valendo.
- **Camada de repositório para todo o app.** Só o caminho de lançamentos, que é onde a duplicação está comprovada. Clientes, MRR e empresa continuam consultando o Supabase direto de suas telas.
- **Quebrar `balanco_screen.dart` e `detalhes_lancamento_screen.dart` em vários arquivos.** São grandes, mas coesos (gráficos desenhados à mão; o modal unificado de detalhes). Fica registrado como observação, não como trabalho desta spec.
- **Qualquer mudança de UI, texto ou fluxo.** Se durante a implementação aparecer uma inconsistência visual entre as telas duplicadas, ela é reportada ao usuário e resolvida em spec própria — não corrigida de carona aqui.
- Migrations e Edge Functions: esta spec não toca no banco nem no backend.

## Perguntas em aberto

1. **Onde mora o repositório de lançamentos?** `lib/lancamentos/lancamentos_repository.dart` (junto do modelo e do `ia_service`) parece o lugar natural, mas Home/Balanço/Histórico não são do domínio `lancamentos`. Precisa de decisão antes do design.
2. **Uma spec só ou fatiada?** São 4 telas grandes. Dá para fazer tudo em uma leva, ou dividir em duas etapas (1: modelo + repositório; 2: componentes visuais) para reduzir o risco de uma sessão só. Recomendação: fatiar, com a etapa 1 primeiro — ela é a que elimina o risco de divergência de comportamento.
