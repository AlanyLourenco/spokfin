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

/// Formato "$ 1,250.00" (separador de milhar vírgula, decimal ponto) usado
/// em telas cuja referência de design pede esse estilo explicitamente
/// (Home, Detalhes/Editar Lançamento) — as demais telas usam [formatarMoeda].
String formatarValorCifrao(num valor) {
  final negativo = valor < 0;
  final absoluto = valor.abs();
  final partes = absoluto.toStringAsFixed(2).split('.');
  final inteiro = partes[0];

  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write(',');
    buffer.write(inteiro[i]);
  }

  return '${negativo ? '-' : ''}\$ $buffer.${partes[1]}';
}

const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

/// Normaliza um nome pra comparação tolerante a diferenças de acentuação,
/// espaçamento e maiúsculas/minúsculas — ex: "Damião Torneiro" e
/// "damiaotorneiro" viram a mesma string ("damiaotorneiro"). Usado pra casar
/// o nome de cliente/fornecedor que a IA extrai (que vem com acentuação
/// "correta") com o nome como o usuário cadastrou de fato.
String normalizarNome(String texto) {
  final semEspacos = texto.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final buffer = StringBuffer();
  for (final rune in semEspacos.runes) {
    final char = String.fromCharCode(rune);
    final indice = _comAcento.indexOf(char);
    buffer.write(indice == -1 ? char : _semAcento[indice]);
  }
  return buffer.toString();
}
