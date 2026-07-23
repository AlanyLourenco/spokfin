/// Formata um valor em Reais com separador de milhar ("R$ 1.234,56").
/// O sinal (se negativo) já vem embutido — não precisa prefixar "-" de fora.
String formatarMoeda(num valor) {
  final negativo = valor < 0;
  final absoluto = valor.abs();
  final partes = absoluto.toStringAsFixed(2).split('.');
  final inteiro = partes[0];
  final decimal = partes[1];

  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }

  return '${negativo ? '-' : ''}R\$ $buffer,$decimal';
}
