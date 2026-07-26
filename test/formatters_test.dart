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

  group('formatarData', () {
    test('formata como dd/mm/aaaa com zero à esquerda', () {
      expect(formatarData(DateTime(2026, 7, 23)), '23/07/2026');
      expect(formatarData(DateTime(2026, 1, 5)), '05/01/2026');
    });
  });

  group('formatarDataCurta', () {
    test('formata como dd/mm, sem ano', () {
      expect(formatarDataCurta(DateTime(2026, 7, 23)), '23/07');
      expect(formatarDataCurta(DateTime(2026, 1, 5)), '05/01');
    });
  });

  group('formatarDataIso', () {
    test('formata como aaaa-mm-dd com zero à esquerda', () {
      expect(formatarDataIso(DateTime(2026, 7, 23)), '2026-07-23');
      expect(formatarDataIso(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('iniciaisDoNome', () {
    test('pega a primeira letra das duas primeiras palavras', () {
      expect(iniciaisDoNome('João da Silva'), 'JD');
      expect(iniciaisDoNome('Maria'), 'M');
    });

    test('retorna "?" pra nome vazio ou só espaços', () {
      expect(iniciaisDoNome(''), '?');
      expect(iniciaisDoNome('   '), '?');
    });

    test('ignora espaços extras nas bordas', () {
      expect(iniciaisDoNome('  Ana Paula  '), 'AP');
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
