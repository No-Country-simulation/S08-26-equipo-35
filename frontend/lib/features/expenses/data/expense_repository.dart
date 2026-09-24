import '../../../core/network/api_client.dart';
import 'expense.dart';

class ExpenseRepository {
  ExpenseRepository._();
  static final instance = ExpenseRepository._();

  Future<List<Expense>> listGroupExpenses(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/expenses', authenticated: true);
    final list = response as List<dynamic>;
    return list.map((item) => Expense.fromJson(item as Map<String, dynamic>)).toList();
  }
}
