import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../shared/app_card.dart';
import '../shared/formatters.dart';
import '../theme.dart';
import 'lancamento_detalhado.dart';

const _corDescricao = Color(0xFF5EEAD4);
const _corCliente = Color(0xFF60A5FA);
const _corData = Color(0xFFFBBF24);

Future<void> mostrarRecibo(
  BuildContext context, {
  required LancamentoDetalhado lancamento,
  required int numero,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recibo de Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const RotuloCard('SPOKFIN', letterSpacing: 1),
            Text(
              'Recibo #$numero',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24, color: AppColors.border),
            _linha('Descrição', lancamento.descricao, _corDescricao),
            _linha('Cliente', lancamento.clienteNome ?? '—', _corCliente),
            _linha('Data', formatarData(lancamento.data), _corData),
            _linha(
              'Categoria',
              lancamento.categoria.isEmpty ? '—' : lancamento.categoria,
              _corDescricao,
            ),
            const Divider(height: 24, color: AppColors.border),
            const Text(
              'TOTAL PAGO',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              formatarMoeda(lancamento.valor),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  _compartilharRecibo(lancamento: lancamento, numero: numero),
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Compartilhar Recibo'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _linha(String label, String valor, Color cor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(
          valor,
          style: TextStyle(color: cor, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Future<void> _compartilharRecibo({
  required LancamentoDetalhado lancamento,
  required int numero,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recibo de Pagamento',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'SPOKFIN',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            'Recibo #$numero',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          _linhaPdf('Descrição', lancamento.descricao),
          _linhaPdf('Cliente', lancamento.clienteNome ?? '—'),
          _linhaPdf('Data', formatarData(lancamento.data)),
          _linhaPdf(
            'Categoria',
            lancamento.categoria.isEmpty ? '—' : lancamento.categoria,
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'TOTAL PAGO',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            formatarMoeda(lancamento.valor),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: 'recibo_$numero.pdf');
}

pw.Widget _linhaPdf(String label, String valor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey)),
        pw.Text(valor, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}
