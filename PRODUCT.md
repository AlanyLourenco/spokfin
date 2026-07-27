# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Microempreendedores Individuais (MEI) formalizados e autônomos/freelancers informais (sem CNPJ) que faturam sozinhos e precisam controlar entradas e saídas do próprio negócio. MEI é o caso mais comum, não o único — o produto não exige CNPJ para ser útil. A situação recorrente: algo acontece (recebimento, compra, assinatura vencendo) e o usuário precisa registrar isso rápido, sem abrir planilha, sem digitar campo por campo.

## Product Purpose

Dar visibilidade real de fluxo de caixa a quem, hoje, não registra nada porque o custo de digitar cada lançamento manualmente (descrição, categoria, cliente, data) é alto demais para o dia a dia de quem trabalha sozinho. Sucesso é o usuário saber, a qualquer momento, quanto tem, quanto vai receber, quanto deve, e para quem — sem esforço de digitação.

## Positioning

O usuário fala ou digita o que aconteceu em português natural ("recebi 300 do João pela consultoria de ontem"); o produto transcreve (quando é áudio) e extrai o lançamento estruturado inteiro via IA — tipo, valor, categoria, status, cliente/fornecedor, data — abrindo uma tela de confirmação já preenchida. Nenhum campo é digitado do zero no caminho comum, e nada é salvo sem revisão humana. Um concorrente que exige preencher um formulário estruturado (mesmo que bonito) não reproduz esse mecanismo.

## Operating Context

Uso diário, geralmente no celular via navegador (web-first, Flutter web), no momento em que o dinheiro entra ou sai — depois de um atendimento, uma compra, um recebimento via PIX. Abas: Home (saldo consolidado, alertas de vencimento, atividade recente), Balanço (mensal, entradas x saídas, gastos por categoria), MRR (assinaturas recorrentes com alerta de atraso), Histórico (filtro por período, exportação em PDF), Clientes e Fornecedores (cadastro com CPF/CNPJ e chave PIX validados). Recibos em PDF são gerados no dispositivo do usuário, nada fica armazenado no servidor. Contexto brasileiro: PIX, CPF/CNPJ, LGPD.

## Capabilities and Constraints

- IA (Google Gemini, camada gratuita) faz transcrição de áudio e extração estruturada de lançamento — desenhado assumindo uso real em camada gratuita: limite de caracteres/duração antes de chamar a IA, detecção de "limite de uso atingido", teto de tokens de saída.
- Multi-tenancy via RLS (Postgres/Supabase) — toda tabela isolada por `empresa_id`, nenhuma query do cliente pode vazar dado de outra empresa.
- Fornecedores não são uma tabela separada — são `clientes` com `tipo = 'fornecedor'`.
- LGPD: termos de uso/privacidade, consentimento explícito no cadastro, exclusão de conta sob demanda.
- Web é a plataforma alvo principal; toolchain Android/iOS existe mas não é prioridade agora (não tratar como produto nativo adaptativo).

## Brand Commitments

Nome: spokfinRM. Tom de voz: neutro e profissional nos textos do produto (mensagens, confirmações, erros) — mesmo que o input do usuário seja informal/coloquial, a voz do produto não replica esse informalismo.

## Evidence on Hand

Nenhum case, depoimento ou dado de uso real de clientes documentado ainda — não inventar testemunhos, benchmarks ou métricas de adoção em trabalho futuro.

## Product Principles

- Nunca salvar um lançamento sem revisão/confirmação humana, por mais confiante que a extração de IA esteja.
- Minimizar digitação no caminho comum — cada campo que o usuário precisa preencher manualmente é uma falha do mecanismo central do produto.
- Projetar a integração de IA assumindo camada gratuita e uso real (limites, custo, falha graciosa), não só o caminho feliz.
- Isolamento de dados por empresa é inegociável — qualquer feature nova respeita RLS/`empresa_id` desde o desenho.
- MEI é o caso mais comum, não uma exigência — não bloquear ou pressupor CNPJ nos fluxos.

## Accessibility & Inclusion

Nenhum requisito formal definido ainda (ex: WCAG AA) — boas práticas gerais de contraste e tamanho de toque bastam por ora. Não tratar como decidido; revisitar se um requisito específico surgir.
