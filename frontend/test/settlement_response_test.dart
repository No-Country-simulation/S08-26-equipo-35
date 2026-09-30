import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/features/groups/data/group_detail.dart';

/// base válida de un settlement, para pisar solo el campo que se prueba.
Map<String, dynamic> _settlementJson({
  Object? settledAt = '2026-09-30T02:18:09.965133Z',
  Object? status = 'PENDING',
  bool includeSettledAt = true,
}) {
  return {
    'settlement_id': 's-1',
    'group_id': 'g-1',
    'payer_user_id': 'u-1',
    'receiver_user_id': 'u-2',
    'amount': '50.00',
    'status': status,
    if (includeSettledAt) 'settled_at': settledAt,
  };
}

void main() {
  group('SettlementResponse.fromJson', () {
    test('parsea el caso normal', () {
      final s = SettlementResponse.fromJson(_settlementJson());

      expect(s.settlementId, 's-1');
      expect(s.amount, '50.00');
      expect(s.status, 'PENDING');
      expect(s.settledAt, isNotNull);
    });

    test('settled_at null no revienta (pago pendiente)', () {
      // El OpenAPI marca settled_at como requerido, pero un pago PENDING no
      // tiene fecha de liquidación. Antes: DateTime.parse(null) -> crash.
      final s = SettlementResponse.fromJson(_settlementJson(settledAt: null));

      expect(s.settledAt, isNull);
    });

    test('settled_at ausente no revienta', () {
      final s = SettlementResponse.fromJson(
        _settlementJson(includeSettledAt: false),
      );

      expect(s.settledAt, isNull);
    });

    test('settled_at con formato inválido no revienta', () {
      final s = SettlementResponse.fromJson(
        _settlementJson(settledAt: 'no-es-una-fecha'),
      );

      expect(s.settledAt, isNull);
    });

    test('status ausente cae al default PENDING', () {
      final s = SettlementResponse.fromJson(
        _settlementJson()..remove('status'),
      );

      expect(s.status, 'PENDING');
    });
  });

  group('DebtResponse.fromJson', () {
    Map<String, dynamic> debtJson({Object? status = 'PENDING'}) => {
          'debtor_user_id': 'u-1',
          'debtor_name': 'Ana',
          'creditor_user_id': 'u-2',
          'creditor_name': 'Beto',
          'amount': '25.00',
          if (status != null) 'status': status,
        };

    test('parsea el desglose de gastos', () {
      final d = DebtResponse.fromJson({
        ...debtJson(status: 'PAID'),
        'expenses': [
          {
            'expense_id': 'e-1',
            'title': 'Cena',
            'expense_category': 'Food & Drink',
            'amount': '25.00',
          },
        ],
      });

      expect(d.status, 'PAID');
      expect(d.expenses, hasLength(1));
      expect(d.expenses.first.title, 'Cena');
    });

    test('status ausente cae al default PENDING', () {
      final d = DebtResponse.fromJson(debtJson(status: null));

      expect(d.status, 'PENDING');
    });

    test('expenses ausente queda vacío', () {
      final d = DebtResponse.fromJson(debtJson());

      expect(d.expenses, isEmpty);
    });
  });
}
