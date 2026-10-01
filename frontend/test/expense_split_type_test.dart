import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/features/expenses/data/expense.dart';

/// Tests de `SplitType` — el enum que se parsea desde la API.
///
/// El caso importante es `unknown`: antes el parseo era
/// `value == 'EQUAL' ? equal : exactAmount`, así que cualquier valor nuevo del
/// enum del backend pasaba por "custom split" y la UI abría el editor de
/// reparto manual para un modo que no entendía.
void main() {
  group('splitTypeFromJson', () {
    test('reconoce los dos valores del enum de la API', () {
      expect(splitTypeFromJson('EQUAL'), SplitType.equal);
      expect(splitTypeFromJson('EXACT_AMOUNT'), SplitType.exactAmount);
    });

    test('un valor desconocido es unknown, no exactAmount', () {
      // Éste es el bug que previene: con el ternario anterior esto devolvía
      // `exactAmount` y la app reafirmaba un tipo de reparto que no conoce.
      expect(splitTypeFromJson('PERCENTAGE'), SplitType.unknown);
      expect(splitTypeFromJson('WEIGHTED'), SplitType.unknown);
    });

    test('no es case-insensitive a propósito', () {
      // El enum de FastAPI es exacto en mayúsculas. 'equal' minúscula no es un
      // valor válido, así que cae en unknown en vez de adivinarse.
      expect(splitTypeFromJson('equal'), SplitType.unknown);
      expect(splitTypeFromJson(''), SplitType.unknown);
    });
  });

  group('splitTypeToApi', () {
    test('ida y vuelta de los dos tipos conocidos', () {
      expect(splitTypeToApi(SplitType.equal), 'EQUAL');
      expect(splitTypeToApi(SplitType.exactAmount), 'EXACT_AMOUNT');
    });

    test('unknown serializa a null, no a un valor inventado', () {
      // Es lo que evita que `updateExpense` pise el `split_type` de un gasto
      // cuyo reparto no entiende: `null` hace que el campo no se mande.
      expect(splitTypeToApi(SplitType.unknown), isNull);
    });
  });

  group('splitTypeLabel', () {
    test('etiqueta los tipos conocidos', () {
      expect(splitTypeLabel(SplitType.equal), 'Reparto igual');
      expect(splitTypeLabel(SplitType.exactAmount), 'Reparto personalizado');
    });

    test('unknown no afirma conocer el modo', () {
      expect(splitTypeLabel(SplitType.unknown), 'Reparto');
    });
  });

  group('Expense.fromJson tolera montos malformados', () {
    Map<String, dynamic> expenseJson({dynamic total = '10.00'}) => {
          'expense_id': 'e1',
          'group_id': 'g1',
          'payer_user_id': 'u1',
          'title': 'Cena',
          'total_amount': total,
          'split_type': 'EQUAL',
          'expense_category': 'food',
          'created_at': '2026-02-01T20:00:00Z',
          'splits': [
            {'split_id': 's1', 'user_id': 'u1', 'amount_owed': '5.00'},
          ],
        };

    test('parsea el monto como string, que es lo que manda la spec', () {
      expect(Expense.fromJson(expenseJson()).totalAmount, 10.0);
    });

    test('un monto numérico no tumba el parseo del gasto entero', () {
      // Antes: `double.parse(10.0 as String)` → TypeError, y con él toda la
      // lista de gastos del grupo.
      expect(Expense.fromJson(expenseJson(total: 10.0)).totalAmount, 10.0);
    });

    test('un monto ilegible queda en 0 y el resto del gasto se conserva', () {
      final expense = Expense.fromJson(expenseJson(total: 'mucho'));
      expect(expense.totalAmount, 0.0);
      expect(expense.title, 'Cena');
      expect(expense.splits, hasLength(1));
    });

    test('los splits también toleran monto numérico', () {
      final json = expenseJson();
      json['splits'] = [
        {'split_id': 's1', 'user_id': 'u1', 'amount_owed': 5.0},
      ];
      expect(Expense.fromJson(json).splits.first.amountOwed, 5.0);
    });

    test('splits ausente es lista vacía, no un fallo', () {
      final json = expenseJson()..remove('splits');
      expect(Expense.fromJson(json).splits, isEmpty);
    });
  });
}
