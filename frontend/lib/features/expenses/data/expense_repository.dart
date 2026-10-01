import '../../../core/network/api_client.dart';
import 'expense.dart';

class ExpenseRepository {
  ExpenseRepository._();
  static final instance = ExpenseRepository._();

  Future<List<Expense>> listGroupExpenses(String groupId) async {
    final response = await ApiClient.get(
      '/groups/$groupId/expenses',
      authenticated: true,
    );
    if (response is! List<dynamic>) {
      return [];
    }
    return response
        .map((item) => Expense.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> getExpense(String expenseId) async {
    final response = await ApiClient.get('/expenses/$expenseId', authenticated: true);
    return Expense.fromJson(response);
  }

  /// Edita un gasto. `ExpenseUpdate` tiene los 6 campos opcionales, así que
  /// sólo se manda lo que cambió de verdad: mandar `null` explícito puede
  /// pisar el valor guardado en el backend.
  ///
  /// `splits` sólo tiene sentido junto con `splitType`: si se cambia el
  /// tipo de reparto hay que mandar también los splits nuevos, o el backend
  /// queda con un EQUAL sin repartos (o al revés).
  Future<Expense> updateExpense({
    required String expenseId,
    String? title,
    double? totalAmount,
    String? payerUserId,
    SplitType? splitType,
    String? expenseCategory,
    List<({String userId, double amountOwed})>? splits,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (totalAmount != null) body['total_amount'] = totalAmount;
    if (payerUserId != null) body['payer_user_id'] = payerUserId;
    if (splitType != null) {
      // Sólo se manda si el app lo reconoce (ver `splitTypeToApi`): mandar
      // `EXACT_AMOUNT` para un tipo desconocido pisaría el reparto de un
      // gasto que el usuario no tocó.
      final wire = splitTypeToApi(splitType);
      if (wire != null) body['split_type'] = wire;
    }
    if (expenseCategory != null) body['expense_category'] = expenseCategory;
    if (splits != null) {
      body['splits'] = splits
          .map((s) => {'user_id': s.userId, 'amount_owed': s.amountOwed})
          .toList();
    }
    final response = await ApiClient.put('/expenses/$expenseId', body, authenticated: true);
    return Expense.fromJson(response);
  }

  Future<void> deleteExpense(String expenseId) async {
    await ApiClient.delete('/expenses/$expenseId', authenticated: true);
  }

  /// Crea un gasto. `splits` siempre se manda explícito (aunque sea
  /// EQUAL) para no depender de que el backend calcule las partes iguales
  /// solo — así el balance que calculamos en el cliente nunca tiene que
  /// adivinar (ver balance_calculator.dart).
  Future<Expense> createExpense({
    required String groupId,
    required String payerUserId,
    required String title,
    required double totalAmount,
    required SplitType splitType,
    required String expenseCategory,
    required List<({String userId, double amountOwed})> splits,
  }) async {
    final response = await ApiClient.post('/groups/$groupId/expenses', {
      'payer_user_id': payerUserId,
      'title': title,
      'total_amount': totalAmount,
      // `unknown` es inalcanzable desde acá: el toggle de la UI sólo ofrece
      // igual / custom. Si llegara, el default a 'EQUAL' es inocuo porque los
      // `splits` de abajo siempre se mandan explícitos — el tipo es
      // etiqueta, las partes las define el body, no el enum.
      'split_type': splitTypeToApi(splitType) ?? 'EQUAL',
      'expense_category': expenseCategory,
      'splits': splits
          .map((s) => {'user_id': s.userId, 'amount_owed': s.amountOwed})
          .toList(),
    }, authenticated: true);
    return Expense.fromJson(response);
  }
}
