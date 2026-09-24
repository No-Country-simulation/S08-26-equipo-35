enum SplitType { equal, exactAmount }

SplitType _splitTypeFromJson(String value) {
  return value == 'EQUAL' ? SplitType.equal : SplitType.exactAmount;
}

/// Un split individual dentro de un gasto (cuánto le toca a una persona).
class ExpenseSplit {
  const ExpenseSplit({
    required this.splitId,
    required this.userId,
    required this.amountOwed,
  });

  final String splitId;
  final String userId;
  final double amountOwed;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      splitId: json['split_id'] as String,
      userId: json['user_id'] as String,
      // OJO: la API devuelve los montos como STRING (para no perder
      // precisión decimal), no como número — hay que parsearlos.
      amountOwed: double.parse(json['amount_owed'] as String),
    );
  }
}

/// Respuesta de un gasto (GET /groups/{id}/expenses, GET /expenses/{id}).
class Expense {
  const Expense({
    required this.expenseId,
    required this.groupId,
    required this.payerUserId,
    required this.title,
    required this.totalAmount,
    required this.splitType,
    required this.expenseCategory,
    required this.createdAt,
    required this.splits,
  });

  final String expenseId;
  final String groupId;
  final String payerUserId;
  final String title;
  final double totalAmount;
  final SplitType splitType;
  final String expenseCategory;
  final DateTime createdAt;
  final List<ExpenseSplit> splits;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'] as String,
      groupId: json['group_id'] as String,
      payerUserId: json['payer_user_id'] as String,
      title: json['title'] as String,
      totalAmount: double.parse(json['total_amount'] as String),
      splitType: _splitTypeFromJson(json['split_type'] as String),
      expenseCategory: json['expense_category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      splits: (json['splits'] as List<dynamic>? ?? const [])
          .map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
