import '../../expenses/data/expense.dart';

/// Cuánto te afecta UN gasto puntual: positivo si te deben (lo pagaste y
/// otros tenían que aportar su parte), negativo si a vos te tocaba pagar
/// tu parte.
///
/// El balance AGREGADO por grupo ya no se calcula acá: viene del backend
/// en `/balance-summary`. Esto queda sólo para el estado (+/-) de cada
/// fila de gasto individual, que el summary no expone.
double myNetForExpense(Expense expense, String myUserId, int memberCount) {
  final myShare = myShareForExpense(expense, myUserId, memberCount);
  final myContribution = expense.payerUserId == myUserId
      ? expense.totalAmount
      : 0.0;
  return myContribution - myShare;
}

double myShareForExpense(Expense expense, String myUserId, int memberCount) {
  for (final split in expense.splits) {
    if (split.userId == myUserId) return split.amountOwed;
  }
  // Sin splits explícitos sólo se puede dividir si el tipo es EQUAL. Para
  // `SplitType.unknown` se devuelve 0 en vez de asumir una división: el
  // reparto real lo calculó el backend con un criterio que la app no conoce,
  // y adivinarlo deformaría el "+/-" que muestra la fila.
  if (expense.splits.isEmpty &&
      expense.splitType == SplitType.equal &&
      memberCount > 0) {
    return expense.totalAmount / memberCount;
  }
  return 0;
}
