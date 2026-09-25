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

  Future<Expense> updateExpense({
    required String expenseId,
    String? title,
    double? totalAmount,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (totalAmount != null) body['total_amount'] = totalAmount;
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
      'split_type': splitType == SplitType.equal ? 'EQUAL' : 'EXACT_AMOUNT',
      'expense_category': expenseCategory,
      'splits': splits
          .map((s) => {'user_id': s.userId, 'amount_owed': s.amountOwed})
          .toList(),
    }, authenticated: true);
    return Expense.fromJson(response);
  }
}
