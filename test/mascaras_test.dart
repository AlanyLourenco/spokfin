import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/shared/mascaras.dart';

void main() {
  group('telefoneValido', () {
    test('aceita fixo (10 dígitos) e celular (11 dígitos)', () {
      expect(telefoneValido('(11) 2345-6789'), isTrue);
      expect(telefoneValido('(11) 92345-6789'), isTrue);
    });

    test('rejeita menos de 10 dígitos', () {
      expect(telefoneValido('(11) 234-567'), isFalse);
    });
  });

  group('emailValido', () {
    test('aceita e-mails simples', () {
      expect(emailValido('joao@exemplo.com'), isTrue);
      expect(emailValido('joao.silva+pix@exemplo.com.br'), isTrue);
    });

    test('rejeita textos sem @ ou domínio', () {
      expect(emailValido('joao'), isFalse);
      expect(emailValido('joao@'), isFalse);
      expect(emailValido('joao@exemplo'), isFalse);
    });
  });

  group('cpfValido', () {
    test('aceita um CPF válido conhecido', () {
      expect(cpfValido('111.444.777-35'), isTrue);
    });

    test('rejeita dígitos repetidos', () {
      expect(cpfValido('111.111.111-11'), isFalse);
    });

    test('rejeita dígito verificador errado', () {
      expect(cpfValido('111.444.777-34'), isFalse);
    });

    test('rejeita tamanho errado', () {
      expect(cpfValido('123.456.789'), isFalse);
    });
  });

  group('cnpjValido', () {
    test('aceita um CNPJ válido conhecido', () {
      expect(cnpjValido('11.222.333/0001-81'), isTrue);
    });

    test('rejeita dígitos repetidos', () {
      expect(cnpjValido('11.111.111/1111-11'), isFalse);
    });

    test('rejeita dígito verificador errado', () {
      expect(cnpjValido('11.222.333/0001-80'), isFalse);
    });
  });

  group('cpfCnpjValido', () {
    test('escolhe o algoritmo certo pela quantidade de dígitos', () {
      expect(cpfCnpjValido('111.444.777-35'), isTrue);
      expect(cpfCnpjValido('11.222.333/0001-81'), isTrue);
    });

    test('rejeita quantidade de dígitos que não é nem CPF nem CNPJ', () {
      expect(cpfCnpjValido('123456'), isFalse);
    });
  });

  group('TelefoneInputFormatter', () {
    test('formata progressivamente até 10 dígitos como fixo', () {
      final formatter = TelefoneInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1123456789'),
      );
      expect(resultado.text, '(11) 2345-6789');
    });

    test('formata 11 dígitos como celular', () {
      final formatter = TelefoneInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11923456789'),
      );
      expect(resultado.text, '(11) 92345-6789');
    });
  });

  group('CpfCnpjInputFormatter', () {
    test('formata 11 dígitos como CPF', () {
      final formatter = CpfCnpjInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11144477735'),
      );
      expect(resultado.text, '111.444.777-35');
    });

    test('formata 14 dígitos como CNPJ', () {
      final formatter = CpfCnpjInputFormatter();
      final resultado = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11222333000181'),
      );
      expect(resultado.text, '11.222.333/0001-81');
    });
  });

  group('DataInputFormatter', () {
    TextEditingValue formatar(String texto) => DataInputFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: texto),
        );

    test('insere as barras sozinho conforme os dígitos entram', () {
      expect(formatar('2').text, '2');
      expect(formatar('23').text, '23');
      expect(formatar('236').text, '23/6');
      expect(formatar('2306').text, '23/06');
      expect(formatar('230620').text, '23/06/20');
      expect(formatar('23062005').text, '23/06/2005');
    });

    test('descarta dígito além dos 8 e ignora o que não é número', () {
      expect(formatar('230620051234').text, '23/06/2005');
      expect(formatar('23/06/2005').text, '23/06/2005');
      expect(formatar('abc23def06').text, '23/06');
    });
  });

  group('dataDeTexto', () {
    test('converte uma data válida', () {
      expect(dataDeTexto('23/06/2005'), DateTime(2005, 6, 23));
      expect(dataDeTexto('29/02/2024'), DateTime(2024, 2, 29));
    });

    test('rejeita data incompleta', () {
      expect(dataDeTexto(''), isNull);
      expect(dataDeTexto('23/06'), isNull);
      expect(dataDeTexto('2/05/2001'), isNull);
    });

    test('rejeita dia que não existe no mês, em vez de deslizar', () {
      // DateTime(2023, 2, 31) viraria 03/03 calado — o validador barra.
      expect(dataDeTexto('31/02/2023'), isNull);
      expect(dataDeTexto('31/04/2023'), isNull);
      expect(dataDeTexto('29/02/2023'), isNull);
    });

    test('rejeita mês e ano fora de faixa', () {
      expect(dataDeTexto('01/13/2023'), isNull);
      expect(dataDeTexto('01/00/2023'), isNull);
      expect(dataDeTexto('01/01/1800'), isNull);
    });
  });
}
