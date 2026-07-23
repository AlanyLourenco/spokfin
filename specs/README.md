# Spec-Driven Development (SDD) — spokfinRM

Convenção para desenvolver features neste projeto: antes de escrever código, escrevemos a especificação. Isso vale a partir de agora — o que já foi construído (Fase 0-2, lançamentos por IA) não será retroativamente especificado, só o que vem daqui pra frente.

## Fluxo

1. **Criar a pasta da feature** em `specs/NNNN-nome-curto/` (copiar de `specs/_template/`).
2. **Escrever `requirements.md`** — o quê e por quê, sem entrar em como. Revisado e aprovado antes de seguir.
3. **Escrever `design.md`** — como: schema, endpoints, telas, decisões técnicas. Revisado antes de implementar.
4. **Escrever `tasks.md`** — checklist de implementação, cada item pequeno o bastante pra marcar como concluído em uma sessão.
5. **Implementar** seguindo o `tasks.md`, marcando cada item (`- [x]`) conforme termina.
6. Specs são vivas: se a implementação exigir mudar o design, o `design.md` é atualizado antes de continuar — ele nunca fica desatualizado em relação ao código.

## Numeração

`NNNN` é sequencial (`0001`, `0002`, ...), na ordem em que a feature foi especificada — não precisa bater com a ordem de implementação.

## Índice de specs

| # | Feature | Status |
|---|---------|--------|
| [0001](0001-mrr-assinantes/) | MRR / Assinantes Mensais | Implementado — falta rodar migration + testar |
| [0002](0002-ficha-cliente/) | Ficha do Cliente (débito, encarregados, histórico) | Implementado — falta rodar migration + testar |

## Catálogo de histórias de usuário

[`historias-de-usuario.md`](historias-de-usuario.md) documenta, retroativamente, o comportamento esperado de cada tela do app como histórias de usuário — todas as lacunas identificadas na primeira rodada já foram implementadas.

## Requisitos e cronograma

[`requisitos-e-cronograma.md`](requisitos-e-cronograma.md) consolida requisitos funcionais e não-funcionais (implementados e pendentes) e um cronograma de execução por dependência para o que falta — testes, performance, LGPD, distribuição nas lojas, etc.
