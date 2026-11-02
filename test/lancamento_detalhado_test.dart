import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/lancamentos/lancamento_detalhado.dart';
import 'package:spokfin/lancamentos/status_lancamento.dart';

void main() {
  group('LancamentoDetalhado.deTransacao', () {
    test('mapeia uma linha de transacoes e assume status pago', () {
      final l = LancamentoDetalhado.deTransacao({
        'id': 't1',
        'descricao': 'Corte de cabelo',
        'categoria': 'Serviços',
        'valor': 50,
        'tipo': 'entrada',
        'data_transacao': '2026-09-01',
        'cliente_id': 'c1',
        'nota_fiscal_status': 'pendente',
      }, clienteNome: 'Maria');

      expect(l.id, 't1');
      expect(l.origem, 'transacao');
      expect(l.status, 'pago');
      expect(l.pago, isTrue);
      expect(l.entrada, isTrue);
      expect(l.statusLabel, 'Pago');
      expect(l.valor, 50.0);
      expect(l.data, DateTime(2026, 9, 1));
      expect(l.clienteId, 'c1');
      expect(l.clienteNome, 'Maria');
      expect(l.notaFiscalStatus, 'pendente');
    });

    test('descricao, categoria e nota fiscal nulas viram os padrões', () {
      final l = LancamentoDetalhado.deTransacao({
        'id': 't2',
        'descricao': null,
        'categoria': null,
        'valor': 10.5,
        'tipo': 'saida',
        'data_transacao': '2026-08-15',
        'cliente_id': null,
        'nota_fiscal_status': null,
      });

      expect(l.descricao, '');
      expect(l.categoria, '');
      expect(l.notaFiscalStatus, 'nao_aplicavel');
      expect(l.entrada, isFalse);
      expect(l.clienteId, isNull);
      expect(l.clienteNome, isNull);
    });
  });

  group('LancamentoDetalhado.deConta', () {
    test('traduz receber/pagar para entrada/saida', () {
      final receber = LancamentoDetalhado.deConta({
        'id': 'c1',
        'descricao': 'Mensalidade',
        'categoria': 'Serviços',
        'valor': 200,
        'tipo': 'receber',
        'vencimento': '2026-09-10',
        'status': 'pendente',
        'status_efetivo': 'pendente',
        'cliente_id': null,
        'nota_fiscal_status': 'nao_aplicavel',
      });
      final pagar = LancamentoDetalhado.deConta({
        'id': 'c2',
        'descricao': 'Aluguel',
        'categoria': 'Fixos',
        'valor': 900,
        'tipo': 'pagar',
        'vencimento': '2026-09-05',
        'status': 'pendente',
        'status_efetivo': 'atrasado',
        'cliente_id': null,
        'nota_fiscal_status': 'nao_aplicavel',
      });

      expect(receber.tipo, 'entrada');
      expect(receber.origem, 'conta');
      expect(receber.data, DateTime(2026, 9, 10));
      expect(pagar.tipo, 'saida');
    });

    test('prefere status_efetivo ao status gravado', () {
      final l = LancamentoDetalhado.deConta({
        'id': 'c3',
        'descricao': 'Fornecedor',
        'categoria': '',
        'valor': 80,
        'tipo': 'pagar',
        'vencimento': '2026-08-01',
        'status': 'pendente',
        'status_efetivo': 'atrasado',
        'cliente_id': null,
        'nota_fiscal_status': 'nao_aplicavel',
      });

      expect(l.status, 'atrasado');
      expect(l.statusLabel, 'Atrasado');
      expect(l.pago, isFalse);
    });

    test('cai para status quando a linha vem da tabela crua', () {
      final l = LancamentoDetalhado.deConta({
        'id': 'c4',
        'descricao': 'Fornecedor',
        'categoria': '',
        'valor': 80,
        'tipo': 'pagar',
        'vencimento': '2026-08-01',
        'status': 'pago',
        'cliente_id': null,
        'nota_fiscal_status': 'nao_aplicavel',
      });

      expect(l.status, 'pago');
      expect(l.statusLabel, 'Pago');
      expect(l.pago, isTrue);
    });
  });

  group('rotuloStatus', () {
    test('traduz os três estados e trata desconhecido como pendente', () {
      expect(rotuloStatus('pago'), 'Pago');
      expect(rotuloStatus('atrasado'), 'Atrasado');
      expect(rotuloStatus('pendente'), 'Pendente');
      expect(rotuloStatus('cancelado'), 'Pendente');
    });
  });

  test('copiarCom preserva status e mantém o rótulo coerente', () {
    final original = LancamentoDetalhado.deConta({
      'id': 'c5',
      'descricao': 'Antiga',
      'categoria': 'Fixos',
      'valor': 100,
      'tipo': 'receber',
      'vencimento': '2026-09-01',
      'status_efetivo': 'atrasado',
      'cliente_id': null,
      'nota_fiscal_status': 'nao_aplicavel',
    });
    final copia = original.copiarCom(descricao: 'Nova', valor: 150);

    expect(copia.descricao, 'Nova');
    expect(copia.valor, 150.0);
    expect(copia.status, 'atrasado');
    expect(copia.statusLabel, 'Atrasado');
  });
}
