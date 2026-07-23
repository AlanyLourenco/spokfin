# Requisitos — Ficha do Cliente

## Contexto
Os prints do protótipo mostram uma tela "Clientes e Devedores" mais rica do que a atual: cada cliente na lista mostra a última movimentação e se está em débito, e ao tocar abre uma "Ficha do Cliente" com status financeiro, histórico e contatos (encarregados) vinculados.

## Objetivo
Ao abrir a ficha de um cliente, o usuário vê de imediato se ele deve algo, quanto já pagou, quantos serviços foram prestados, e consegue gerenciar contatos secundários (encarregados) desse cliente.

## Requisitos funcionais
- [ ] Lista de clientes mostra, por cliente: data do último lançamento vinculado, e "Em débito: R$ X" (vermelho) ou "OK" (verde) se não houver pendência
- [ ] Botão "Novo" (cliente) move do FAB pra um botão no AppBar — libera o canto inferior direito
- [ ] Tocar num cliente abre a "Ficha do Cliente": nome, telefone, botão Editar
- [ ] Card de status: "Em Débito: R$ X" ou "Sem Pendências"
- [ ] Card "Total Pago": soma das transações de entrada vinculadas a esse cliente
- [ ] Card "Serviços Prestados": contagem de lançamentos (transações + contas a receber) vinculados a esse cliente
- [ ] Mini gráfico "Interações por mês": contagem de lançamentos por mês, últimos meses
- [ ] Seção "Encarregados": lista de contatos secundários do cliente (nome, cargo, telefone) + adicionar novo
- [ ] Seção "Histórico": lançamentos vinculados a esse cliente, com status
- [ ] Botão flutuante de ações rápidas (Falar/Anotar/Manual) disponível nas abas que não são a Home (Clientes, Histórico, MRR, Balanço), no lugar reservado pelo FAB de "Novo" que subiu pro AppBar

## Fora de escopo
- Editar/excluir encarregados individualmente (só criar e listar por enquanto)
- Vincular um lançamento a um encarregado específico (o vínculo é sempre com o cliente)
- Zoom/detalhe no gráfico de interações — é só uma visão rápida dos últimos meses

## Decisões
- "Projetos" do print vira **"Serviços Prestados"** — contagem de lançamentos vinculados ao cliente, sem criar um conceito novo de "projeto"
- Encarregados é uma tabela nova, com `empresa_id` redundante (denormalizado) pra reaproveitar a mesma política de RLS (`is_member`) das outras tabelas
