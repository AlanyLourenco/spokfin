import 'dart:convert';
import 'dart:typed_data';

import '../main.dart';

class LancamentoExtraido {
  LancamentoExtraido({
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.categoria,
    required this.status,
    required this.querNotaFiscal,
    this.clienteNome,
    DateTime? data,
  }) : data = data ?? DateTime.now();

  factory LancamentoExtraido.fromJson(Map<String, dynamic> json) {
    final dataStr = json['data'] as String?;
    return LancamentoExtraido(
      tipo: json['tipo'] as String,
      valor: (json['valor'] as num).toDouble(),
      descricao: json['descricao'] as String,
      categoria: json['categoria'] as String,
      status: json['status'] as String,
      querNotaFiscal: json['quer_nota_fiscal'] as bool,
      clienteNome: (json['cliente_nome'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['cliente_nome'] as String,
      data: dataStr == null || dataStr.isEmpty
          ? null
          : DateTime.tryParse(dataStr),
    );
  }

  final String tipo;
  final double valor;
  final String descricao;
  final String categoria;
  final String status;
  final bool querNotaFiscal;
  final String? clienteNome;
  final DateTime data;
}

Future<LancamentoExtraido> extrairLancamento(String texto) async {
  final res = await supabase.functions.invoke(
    'parse-lancamento',
    body: {'texto': texto},
  );
  return LancamentoExtraido.fromJson(res.data as Map<String, dynamic>);
}

Future<String> transcreverAudio(
  Uint8List bytes, {
  String mimeType = 'audio/webm',
}) async {
  final res = await supabase.functions.invoke(
    'transcrever-audio',
    body: {'audio_base64': base64Encode(bytes), 'mime_type': mimeType},
  );
  return (res.data as Map<String, dynamic>)['texto'] as String;
}
