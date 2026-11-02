import 'package:flutter/material.dart';

import 'campo_rotulado.dart';
import 'formatters.dart';
import 'mascaras.dart';
import '../theme.dart';

/// Escolhe um intervalo de datas — no lugar do `showDateRangePicker` do
/// Material, que abre um calendário de tela cheia onde o usuário precisa
/// rolar meses até achar as duas pontas, e cujo modo de digitação não tem
/// máscara nenhuma (aceita `23062005` e responde "Formato inválido").
///
/// Aqui: os quatro períodos que respondem quase toda pergunta ficam a um
/// toque, e quem precisa de data exata digita com máscara `dd/mm/aaaa`.
///
/// Devolve `null` se o usuário cancelar.
Future<DateTimeRange?> escolherPeriodo(
  BuildContext context, {
  DateTimeRange? inicial,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SeletorPeriodo(inicial: inicial),
  );
}

class _SeletorPeriodo extends StatefulWidget {
  const _SeletorPeriodo({this.inicial});

  final DateTimeRange? inicial;

  @override
  State<_SeletorPeriodo> createState() => _SeletorPeriodoState();
}

class _SeletorPeriodoState extends State<_SeletorPeriodo> {
  late final TextEditingController _de = TextEditingController(
    text: widget.inicial == null ? '' : formatarData(widget.inicial!.start),
  );
  late final TextEditingController _ate = TextEditingController(
    text: widget.inicial == null ? '' : formatarData(widget.inicial!.end),
  );
  String? _erro;

  @override
  void dispose() {
    _de.dispose();
    _ate.dispose();
    super.dispose();
  }

  void _aplicarAtalho(DateTime inicio, DateTime fim) {
    Navigator.of(context).pop(DateTimeRange(start: inicio, end: fim));
  }

  void _aplicarDigitado() {
    final inicio = dataDeTexto(_de.text);
    final fim = dataDeTexto(_ate.text);

    if (inicio == null || fim == null) {
      setState(() {
        _erro = 'Preencha as duas datas no formato dd/mm/aaaa.';
      });
      return;
    }
    if (fim.isBefore(inicio)) {
      setState(() => _erro = 'A data final não pode ser antes da inicial.');
      return;
    }
    Navigator.of(context).pop(DateTimeRange(start: inicio, end: fim));
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Período',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Atalho(
                  rotulo: 'Últimos 7 dias',
                  aoTocar: () => _aplicarAtalho(
                    hoje.subtract(const Duration(days: 6)),
                    hoje,
                  ),
                ),
                _Atalho(
                  rotulo: 'Últimos 30 dias',
                  aoTocar: () => _aplicarAtalho(
                    hoje.subtract(const Duration(days: 29)),
                    hoje,
                  ),
                ),
                _Atalho(
                  rotulo: 'Este mês',
                  aoTocar: () => _aplicarAtalho(
                    DateTime(hoje.year, hoje.month, 1),
                    hoje,
                  ),
                ),
                _Atalho(
                  rotulo: 'Mês passado',
                  aoTocar: () => _aplicarAtalho(
                    DateTime(hoje.year, hoje.month - 1, 1),
                    DateTime(hoje.year, hoje.month, 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'ou escolha as datas',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CampoData(rotulo: 'De', controle: _de)),
                const SizedBox(width: 12),
                Expanded(child: _CampoData(rotulo: 'Até', controle: _ate)),
              ],
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: const TextStyle(
                  color: AppColors.negative,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _aplicarDigitado,
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoData extends StatelessWidget {
  const _CampoData({required this.rotulo, required this.controle});

  final String rotulo;
  final TextEditingController controle;

  @override
  Widget build(BuildContext context) {
    return CampoRotulado(
      rotulo: rotulo,
      child: TextField(
        controller: controle,
        keyboardType: TextInputType.number,
        inputFormatters: [DataInputFormatter()],
        decoration: const InputDecoration(hintText: 'dd/mm/aaaa'),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.rotulo, required this.aoTocar});

  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          rotulo,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
