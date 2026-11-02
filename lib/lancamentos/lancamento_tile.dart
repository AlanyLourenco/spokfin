import 'package:flutter/material.dart';

import '../shared/formatters.dart';
import '../theme.dart';
import 'lancamento_detalhado.dart';
import 'status_lancamento.dart';

/// A linha de lançamento em lista — a única do app.
///
/// Home, Histórico e Balanço desenhavam a mesma estrutura (descrição,
/// subtítulo, pílula de nota fiscal, valor com sinal e cor) em três widgets
/// separados. As diferenças legítimas viraram os parâmetros abaixo; as que são
/// descuido estão marcadas com o `DV#` que as documenta no `design.md` da spec
/// `0010`, para que a spec que as corrigir saiba qual parâmetro apagar.
///
/// [subtitulo] vem pronto de quem chama porque cada tela compõe campos
/// diferentes por motivo real: a Home mostra `categoria · status`, o Histórico
/// `data · categoria` (o status já está no ícone) e o Balanço
/// `data · Pago · categoria`.
///
/// A lista da Ficha do Cliente não usa este tile — é uma linha compacta de
/// outro desenho (bolinha em vez de ícone, `formatarMoeda` em vez de
/// `formatarValorCifrao`), não uma variação desta.
class LancamentoTile extends StatelessWidget {
  const LancamentoTile({
    super.key,
    required this.lancamento,
    required this.subtitulo,
    required this.onTap,
    this.emDestaque = false,
    this.mostrarIconeStatus = false,
    this.comBordaInferior = false,
    this.mostrarNotaFiscal = true,
    this.pilulaComIcone = false,
  });

  final LancamentoDetalhado lancamento;
  final String subtitulo;
  final VoidCallback onTap;

  /// Texto maior e mais respiro vertical — a lista principal da Home.
  final bool emDestaque;

  /// Marca de pago/não-pago à esquerda (Histórico).
  final bool mostrarIconeStatus;

  /// Separador hairline no rodapé da linha (Histórico, Balanço). A Home usa
  /// `Divider` entre os itens, então não precisa.
  final bool comBordaInferior;

  /// DV3: o Balanço carrega `nota_fiscal_status` e nunca desenha a pílula.
  final bool mostrarNotaFiscal;

  /// DV2: a pílula tem ícone na Home e não tem no Histórico.
  final bool pilulaComIcone;

  @override
  Widget build(BuildContext context) {
    final cor = lancamento.entrada ? AppColors.accent : AppColors.negative;
    final sinal = lancamento.entrada ? '+' : '-';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: emDestaque ? 16 : 14),
        decoration: comBordaInferior
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              )
            : null,
        child: Row(
          children: [
            if (mostrarIconeStatus) ...[
              Icon(
                iconeStatus(lancamento.status),
                color: corIconeStatus(lancamento.status),
                size: 20,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lancamento.descricao,
                    style: TextStyle(
                      fontSize: emDestaque ? 15 : null,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (mostrarNotaFiscal &&
                          lancamento.notaFiscalStatus == 'pendente') ...[
                        const SizedBox(width: 6),
                        PilulaNotaFiscal(comIcone: pilulaComIcone),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sinal ${formatarValorCifrao(lancamento.valor)}',
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.bold,
                fontSize: emDestaque ? 16 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pílula de "NFC-e agendada" — o aviso de que a nota ainda vai ser emitida.
class PilulaNotaFiscal extends StatelessWidget {
  const PilulaNotaFiscal({super.key, this.comIcone = false});

  /// DV2: só a Home mostra o ícone hoje.
  final bool comIcone;

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      color: AppColors.primary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(999),
      ),
      child: comIcone
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 10, color: AppColors.primary),
                SizedBox(width: 3),
                Text('NFC-e agendada', style: estilo),
              ],
            )
          : const Text('NFC-e agendada', style: estilo),
    );
  }
}
