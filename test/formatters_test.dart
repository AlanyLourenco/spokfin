import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/shared/formatters.dart';

void main() {
  group('formatarMoeda', () {
    test('formata valores sem milhar', () {
      expect(formatarMoeda(835), 'R\$ 835,00');
      expect(formatarMoeda(180.5), 'R\$ 180,50');
    });

    test('adiciona separador de milhar a cada 3 dígitos', () {
      expect(formatarMoeda(1250), 'R\$ 1.250,00');
      expect(formatarMoeda(1234567.89), 'R\$ 1.234.567,89');
    });

    test('valores negativos levam o sinal antes de "R\$"', () {
      expect(formatarMoeda(-180), '-R\$ 180,00');
      expect(formatarMoeda(-1250.5), '-R\$ 1.250,50');
    });

    test('zero', () {
      expect(formatarMoeda(0), 'R\$ 0,00');
    });
  });

  group('normalizarNome', () {
    test('remove espaços, acentos e diferenças de maiúscula/minúscula', () {
      expect(normalizarNome('Damião Torneiro'), 'damiaotorneiro');
      expect(normalizarNome('damiaotorneiro'), 'damiaotorneiro');
    });

    test('nomes equivalentes normalizam pro mesmo valor', () {
      expect(
        normalizarNome('João da Silva') == normalizarNome('joaodasilva'),
        isTrue,
      );
    });

    test('mantém nomes sem acento inalterados (só remove espaço/caixa)', () {
      expect(normalizarNome('Peg Pag'), 'pegpag');
    });
  });
}
