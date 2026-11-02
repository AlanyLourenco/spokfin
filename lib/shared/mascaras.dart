import 'package:flutter/services.dart';

/// Máscara dinâmica de telefone brasileiro: `(XX) XXXX-XXXX` (fixo, 10
/// dígitos) ou `(XX) XXXXX-XXXX` (celular, 11 dígitos), reformatando a cada
/// dígito digitado.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;

    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(limitado[i]);
      if (i == 1) buffer.write(') ');
      if (limitado.length <= 10) {
        if (i == 5) buffer.write('-');
      } else {
        if (i == 6) buffer.write('-');
      }
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Máscara dinâmica de CPF (`###.###.###-##`, até 11 dígitos) ou CNPJ
/// (`##.###.###/####-##`, a partir do 12º dígito), reformatando a cada
/// dígito digitado.
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 14 ? digitos.substring(0, 14) : digitos;

    final buffer = StringBuffer();
    if (limitado.length <= 11) {
      for (var i = 0; i < limitado.length; i++) {
        buffer.write(limitado[i]);
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('-');
      }
    } else {
      for (var i = 0; i < limitado.length; i++) {
        buffer.write(limitado[i]);
        if (i == 1 || i == 4) buffer.write('.');
        if (i == 7) buffer.write('/');
        if (i == 11) buffer.write('-');
      }
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Máscara de data `dd/mm/aaaa`, reformatando a cada dígito digitado —
/// o usuário digita só números e as barras aparecem sozinhas.
class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;

    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Converte `dd/mm/aaaa` em [DateTime], ou `null` se a data não existe.
///
/// Rejeita o que o `DateTime.parse` aceitaria calado: 31/02 vira 03/03 num
/// construtor normal, então o resultado é conferido campo a campo.
DateTime? dataDeTexto(String texto) {
  final digitos = _apenasDigitos(texto);
  if (digitos.length != 8) return null;

  final dia = int.parse(digitos.substring(0, 2));
  final mes = int.parse(digitos.substring(2, 4));
  final ano = int.parse(digitos.substring(4, 8));
  if (mes < 1 || mes > 12 || dia < 1 || ano < 1900 || ano > 2200) return null;

  final data = DateTime(ano, mes, dia);
  if (data.day != dia || data.month != mes || data.year != ano) return null;
  return data;
}

String _apenasDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Telefone válido: 10 dígitos (fixo) ou 11 (celular), DDD incluso.
bool telefoneValido(String texto) {
  final digitos = _apenasDigitos(texto);
  return digitos.length == 10 || digitos.length == 11;
}

/// Regex simples de e-mail — suficiente para uma chave PIX, não tenta
/// validar exaustivamente todo o RFC.
final _regexEmail = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

bool emailValido(String texto) => _regexEmail.hasMatch(texto.trim());

bool _digitosRepetidos(String digitos) =>
    RegExp(r'^(\d)\1*$').hasMatch(digitos);

int _digitoVerificadorCpf(List<int> base, int pesoInicial) {
  var soma = 0;
  for (var i = 0; i < base.length; i++) {
    soma += base[i] * (pesoInicial - i);
  }
  final resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

bool cpfValido(String texto) {
  final cpf = _apenasDigitos(texto);
  if (cpf.length != 11 || _digitosRepetidos(cpf)) return false;
  final digitos = cpf.split('').map(int.parse).toList();
  final d1 = _digitoVerificadorCpf(digitos.sublist(0, 9), 10);
  if (d1 != digitos[9]) return false;
  final d2 = _digitoVerificadorCpf(digitos.sublist(0, 10), 11);
  if (d2 != digitos[10]) return false;
  return true;
}

int _digitoVerificadorCnpj(List<int> base) {
  final pesos = base.length == 12
      ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  var soma = 0;
  for (var i = 0; i < base.length; i++) {
    soma += base[i] * pesos[i];
  }
  final resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

bool cnpjValido(String texto) {
  final cnpj = _apenasDigitos(texto);
  if (cnpj.length != 14 || _digitosRepetidos(cnpj)) return false;
  final digitos = cnpj.split('').map(int.parse).toList();
  final d1 = _digitoVerificadorCnpj(digitos.sublist(0, 12));
  if (d1 != digitos[12]) return false;
  final d2 = _digitoVerificadorCnpj(digitos.sublist(0, 13));
  if (d2 != digitos[13]) return false;
  return true;
}

/// Válido como CPF (11 dígitos) ou CNPJ (14 dígitos), conforme a
/// quantidade de dígitos digitados.
bool cpfCnpjValido(String texto) {
  final digitos = _apenasDigitos(texto);
  if (digitos.length == 11) return cpfValido(texto);
  if (digitos.length == 14) return cnpjValido(texto);
  return false;
}
