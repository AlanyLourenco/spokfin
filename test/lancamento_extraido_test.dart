import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/lancamentos/ia_service.dart';

void main() {
  group('LancamentoExtraido.fromJson', () {
    Map<String, dynamic> baseJson({
      String tipo = 'entrada',
      num valor = 100,
      String descricao = 'Consultoria',
      String categoria = 'Serviço',
      String status = 'pago',
      bool querNotaFiscal = false,
      String? clienteNome,
      String? data,
    }) => {
      'tipo': tipo,
      'valor': valor,
      'descricao': descricao,
      'categoria': categoria,
      'status': status,
      'quer_nota_fiscal': querNotaFiscal,
      'cliente_nome': clienteNome,
      'data': data,
    };

    test('parseia os campos básicos corretamente', () {
      final l = LancamentoExtraido.fromJson(
        baseJson(tipo: 'saida', valor: 250.5, status: 'pendente'),
      );
      expect(l.tipo, 'saida');
      expect(l.valor, 250.5);
      expect(l.descricao, 'Consultoria');
      expect(l.categoria, 'Serviço');
      expect(l.status, 'pendente');
      expect(l.querNotaFiscal, false);
    });

    test('cliente_nome nulo vira null', () {
      final l = LancamentoExtraido.fromJson(baseJson(clienteNome: null));
      expect(l.clienteNome, isNull);
    });

    test('cliente_nome vazio ou só espaços vira null', () {
      final l = LancamentoExtraido.fromJson(baseJson(clienteNome: '   '));
      expect(l.clienteNome, isNull);
    });

    test('cliente_nome preenchido é mantido', () {
      final l = LancamentoExtraido.fromJson(baseJson(clienteNome: 'João'));
      expect(l.clienteNome, 'João');
    });

    test('data ausente ou vazia usa o horário atual (não nulo)', () {
      final antes = DateTime.now();
      final l = LancamentoExtraido.fromJson(baseJson(data: null));
      final depois = DateTime.now();
      expect(
        l.data.isAfter(antes.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(l.data.isBefore(depois.add(const Duration(seconds: 1))), isTrue);
    });

    test('data explícita no formato ISO é respeitada', () {
      final l = LancamentoExtraido.fromJson(baseJson(data: '2026-03-05'));
      expect(l.data.year, 2026);
      expect(l.data.month, 3);
      expect(l.data.day, 5);
    });

    test('data inválida cai para o horário atual em vez de lançar erro', () {
      final l = LancamentoExtraido.fromJson(baseJson(data: 'não é uma data'));
      expect(l.data, isNotNull);
    });
  });
}
