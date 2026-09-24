import '../../expenses/data/expense.dart';

/// Calcula el balance neto del usuario en un grupo, sumando todos sus
/// gastos. Positivo = le deben; negativo = debe; cero = está saldado.
///
/// Regla para gastos sin `splits` explícitos: si son de tipo EQUAL, se
/// asume reparto igualitario entre los miembros ACTUALES del grupo — es
/// una aproximación, puede no coincidir con la realidad si la membresía
/// cambió después de crear el gasto. Si no es EQUAL y no trae splits, esa
/// expense no se puede repartir y se ignora en el cálculo.
double calculateNetBalance({
  required List<Expense> expenses,
  required String myUserId,
  required int memberCount,
}) {
  double net = 0;
  for (final expense in expenses) {
    final myShare = _resolveMyShare(expense, myUserId, memberCount);
    final myContribution = expense.payerUserId == myUserId ? expense.totalAmount : 0.0;
    net += myContribution - myShare;
  }
  return net;
}

double _resolveMyShare(Expense expense, String myUserId, int memberCount) {
  for (final split in expense.splits) {
    if (split.userId == myUserId) return split.amountOwed;
  }
  if (expense.splits.isEmpty && expense.splitType == SplitType.equal && memberCount > 0) {
    return expense.totalAmount / memberCount;
  }
  return 0;
}
