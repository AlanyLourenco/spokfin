# Requisitos — Alinhar o front ao protótipo (spokfin-ledger-ai)

## Contexto

O usuário construiu um protótipo do app em [spokfin-ledger-ai.lovable.app](https://spokfin-ledger-ai.lovable.app/) e quer que o front do projeto real fique como ele — **sem perder nenhuma das funcionalidades que o app já tem**, que são muitas e o protótipo não cobre.

O protótipo é um mock React (Tailwind + Inter), sem backend: dados fixos no código, nenhuma tela de login, nenhuma escrita. Ele é uma **referência visual**, não um sistema a portar.

Explorei as 5 telas dele e extraí os tokens reais do CSS:

| Token | Protótipo | Projeto hoje (`AppColors`, spec 0009) |
|---|---|---|
| Fundo | `#04090D` (quase preto) | `#0F172A` (azul-marinho) |
| Superfície | `#0D1520` | `#192134` |
| Superfície 2 | `#0A1119` | `#232B3E` (`surfaceAlt`) |
| Borda | `#1B2533` — **sólida** | `hairline`, branco a 8% |
| Acento | `mint #4ADE80` | `accent #059669` |
| Negativo | `coral #FB7185` | `negative #DC2626` |
| Texto secundário | `#6B7A8F` | `#94A3B8` |
| Texto primário | `#F5F7FA` | `#FFFFFF` |
| Tipografia | Inter, e **só** Inter | Inter + Calistoga (título de tela) |
| Cor de ação | **não existe** — usa o mint | `primary #1E40AF` (azul) |

E as diferenças de estrutura:

- A navegação inferior é uma **pílula flutuante arredondada**, com a aba ativa como um retângulo verde preenchido — hoje é uma barra de largura total.
- O FAB é um círculo verde acima da navegação.
- Telas secundárias têm cabeçalho com seta de voltar + título + uma pílula verde de ação ("Novo", "Nova").
- O protótipo é uma **moldura de celular de largura fixa**, centralizada. O app real hoje ocupa a largura toda do navegador — no monitor, uma linha de lançamento estica por 1366px.
- Valor formatado como `+$ 300.00` (sem espaço entre sinal e cifrão); hoje é `+ $ 300.00`.
- Data no formato `10 Jul 2026` na lista de clientes; hoje é `30/07/2026`.

**A questão central: o protótipo usa verde como cor de ação.** O botão "Falar", a aba ativa, o FAB, "Novo", "Baixar Pagamento" — todos mint. Isso contraria frontalmente a regra que a spec `0009` estabeleceu como *"não negociável"*: azul = ação e UI, verde = dinheiro positivo e status pago, "nunca use verde como cor de ação genérica". Adotar o protótipo como está significa **aposentar essa regra** e reescrever `DESIGN.md` e a seção de cores do `CLAUDE.md`. Não é uma mudança de token, é uma mudança de decisão — e é sua, não minha (ver Perguntas em aberto).

## Objetivo

O app real fica com a linguagem visual do protótipo — paleta, superfícies, navegação flutuante, cabeçalhos e espaçamento —, e **todas** as telas e funcionalidades que existem hoje continuam funcionando exatamente como funcionam.

## Requisitos funcionais

### Visual

- [ ] `AppColors` passa a refletir a paleta do protótipo, com os tokens documentados em `DESIGN.md`.
- [ ] A navegação inferior vira a pílula flutuante com aba ativa preenchida.
- [ ] O FAB e os cabeçalhos de tela secundária seguem o protótipo (seta de voltar + título + pílula de ação).
- [ ] Cartões, bordas e espaçamento seguem as superfícies e a borda sólida do protótipo, via `AppCard` — sem `Container` solto (a convenção atual continua valendo).
- [ ] As 5 telas do protótipo (Home, Balanço, MRR, Histórico, Clientes) ficam visualmente equivalentes a ele.
- [ ] As telas que o protótipo **não** desenhou (login, cadastro, recuperação de senha, onboarding de empresa, Anotar, Falar, Revisar, Detalhes do lançamento, Ficha do Cliente, Ficha do Fornecedor, Ficha do Assinante, Nova Assinatura, Perfil, Termos, Recibo) recebem a mesma linguagem por extensão, e não ficam com a aparência antiga.
- [ ] O motion continua saindo de `AppMotion`; nada de `Duration` solto (convenção da spec `0008`).

### Funcionalidades que **não** podem se perder

Levantadas do código atual; o protótipo não tem nenhuma delas:

- [ ] **Histórico**: busca por texto, filtro de mês/período personalizado, exportar relatório em PDF, paginação de 30 com "Carregar mais".
- [ ] **Balanço**: seletor de período incluindo personalizado (spec `0004`), donut de gastos por categoria, gráfico de entradas vs saídas.
- [ ] **Clientes**: aba Clientes/Fornecedores, busca server-side com paginação, arquivar cliente, formulário com máscara e validação de CPF/CNPJ e telefone, chave PIX de fornecedor.
- [ ] **Ficha do Cliente**: débito, total pago, serviços prestados, interações por mês, encarregados, histórico.
- [ ] **MRR**: ficha do assinante, nova assinatura, baixar pagamento, paginação.
- [ ] **Lançamentos**: captura por voz (`Falar`) e por texto (`Anotar`) com IA Gemini, tela de revisão, modal de detalhes/edição, marcar pago/pendente, gerar recibo, nota fiscal.
- [ ] **Conta**: login, cadastro com consentimento, recuperação de senha, onboarding de empresa, perfil, termos, exclusão de conta (LGPD, spec `0005`).
- [ ] Nenhuma consulta ao Supabase, RPC ou Edge Function muda. Esta spec é de apresentação.
- [ ] O modelo/repositório/tile unificados da spec `0010` continuam sendo o caminho único — o tile novo é uma mudança **dentro** de `LancamentoTile`, não uma volta às cópias por tela.

### Fechamento

- [ ] `flutter analyze` limpo e `flutter test` passando.
- [ ] `DESIGN.md` reescrito para a identidade nova; `CLAUDE.md` atualizado na seção de cores.
- [ ] Cada tela conferida no navegador contra o protótipo.

## Fora de escopo

- **Portar o código do protótipo.** É React/Tailwind; o projeto é Flutter. O que se aproveita é a decisão visual, não o HTML.
- **Copiar as funcionalidades que só existem no protótipo.** Ele tem "Enviar Lembrete" no card do assinante, que o app não tem; e mostra o débito e a contagem de encarregados direto na lista de clientes. São ideias de produto, e viram spec própria se você quiser — não entram de carona numa spec de apresentação.
- **Mudar dado, schema, RPC ou Edge Function.** Nenhuma migration nesta spec.
- **Refazer a arquitetura de estado.** `StatefulWidget` + `setState` + `lancamentos_bus.dart` continuam.
- **Mudar o texto/copy das telas**, salvo onde o protótipo mostra um texto diferente e você aprovar explicitamente.

## Decisões tomadas

1. **O verde não vira cor de ação.** Adota-se do protótipo tudo o mais — superfícies quase pretas, borda sólida, navegação flutuante, coral `#FB7185` no negativo, tipografia — mas `primary` continua azul para ação e UI. A regra da spec `0009` (azul = ação, verde = dinheiro e status pago) **permanece valendo**, e o `DESIGN.md` não precisa ser reescrito nessa parte, só nos tokens de superfície e no negativo.
2. **O conteúdo passa a ser uma coluna centralizada** com largura máxima, como a moldura do protótipo — resolvendo o vão entre descrição e valor que hoje aparece numa tela de 1366px.
3. **A spec `0011` (ambiente local) vem primeiro.** Mexer em 20+ telas sem dado de exemplo e sem poder resetar o banco é o pior cenário para conferir visual — o teste da spec `0010` já esbarrou nisso (base sem conta pendente, sem itens suficientes para paginar).

## Perguntas em aberto

1. **Fatiar em quantas etapas?** São 20+ telas. Sugestão, na linha do que funcionou na `0010`: (1) tokens + `AppCard` + navegação + FAB + a coluna centralizada; (2) as 5 telas principais; (3) as telas secundárias. Cada etapa fecha com analyze/test verdes.
2. **O coral substitui o vermelho em erro também**, ou só em saída de dinheiro? Hoje `AppColors.negative` serve aos dois papéis.
3. **A Calistoga sai?** O protótipo usa só Inter; hoje o título de tela é Calistoga. Manter a Calistoga é um desvio consciente do protótipo, tirá-la aproxima mais.
