import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

/// Lançada quando uma chamada de IA é recusada por limite de uso atingido
/// (`registrar_uso_ia`, 429) — distinta de outros erros pra quem chama poder
/// decidir não tentar de novo (retry só gastaria outra chamada à toa).
class LimiteIaExcedido implements Exception {
  LimiteIaExcedido(this.mensagem);
  final String mensagem;
}

String _mensagemDoErro(FunctionException e, String fallback) {
  final details = e.details;
  if (details is Map && details['error'] is String) {
    return details['error'] as String;
  }
  return fallback;
}

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
  try {
    final res = await supabase.functions.invoke(
      'parse-lancamento',
      body: {'texto': texto},
    );
    return LancamentoExtraido.fromJson(res.data as Map<String, dynamic>);
  } on FunctionException catch (e) {
    if (e.status == 429) {
      throw LimiteIaExcedido(
        _mensagemDoErro(e, 'Limite de uso de IA atingido — tente mais tarde.'),
      );
    }
    rethrow;
  }
}

Future<String> transcreverAudio(
  Uint8List bytes, {
  String mimeType = 'audio/webm',
}) async {
  try {
    final res = await supabase.functions.invoke(
      'transcrever-audio',
      body: {'audio_base64': base64Encode(bytes), 'mime_type': mimeType},
    );
    return (res.data as Map<String, dynamic>)['texto'] as String;
  } on FunctionException catch (e) {
    if (e.status == 429) {
      throw LimiteIaExcedido(
        _mensagemDoErro(e, 'Limite de uso de IA atingido — tente mais tarde.'),
      );
    }
    rethrow;
  }
}
