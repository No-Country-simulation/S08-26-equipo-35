import '../../../core/utils/money.dart';

/// Cómo se repartió un gasto.
///
/// [unknown] existe para que un valor nuevo del enum del backend no se
/// disfrace de `exactAmount`. Con el ternario anterior
/// (`value == 'EQUAL' ? equal : exactAmount`) cualquier valor desconocido
/// pasaba por "custom split": la UI abría el editor de reparto manual para un
/// tipo que no entendía, y el usuario podía pisar un reparto que el backend
/// había calculado de otra forma.
///
/// Hoy el enum de la API es exactamente `EQUAL` / `EXACT_AMOUNT`, así que
/// [unknown] no debería aparecer. Si aparece, es señal de que el backend
/// agregó un modo de reparto y la app quedó vieja: es preferible que se vea
/// raro en una etiqueta a que corrompa datos en pantalla.
enum SplitType { equal, exactAmount, unknown }

SplitType splitTypeFromJson(String value) {
  switch (value) {
    case 'EQUAL':
      return SplitType.equal;
    case 'EXACT_AMOUNT':
      return SplitType.exactAmount;
    default:
      return SplitType.unknown;
  }
}

/// Etiqueta corta para mostrar el modo de reparto junto al monto.
///
/// Para [SplitType.unknown] no se inventa: se dice sólo "Split". La pantalla
/// de detalle muestra los `splits` que vieram del servidor de todos modos, así
/// que el dato no se pierde, pero la app no afirma conocer un modo que no
/// reconoce.
String splitTypeLabel(SplitType type) {
  switch (type) {
    case SplitType.equal:
      return 'Reparto igual';
    case SplitType.exactAmount:
      return 'Reparto personalizado';
    case SplitType.unknown:
      return 'Reparto';
  }
}

/// Serializa el modo de reparto para la API, o `null` si es [SplitType.unknown].
///
/// El `null` importa: `updateExpense` sólo manda `split_type` si esto
/// devuelve algo. Con el ternario anterior, un gasto cuyo `split_type` la app
/// no reconoce se guardaba como `EXACT_AMOUNT` en el primer guardado de
/// cualquier campo — pisando el tipo de un gasto que el usuario no había
/// tocado, y con él los splits que el backend tenía calculados.
///
/// O sea: no mandar el campo es lo conservador y seguro (el backend conserva
/// lo que tenía); mandar el equivocado es destructivo.
String? splitTypeToApi(SplitType type) {
  switch (type) {
    case SplitType.equal:
      return 'EQUAL';
    case SplitType.exactAmount:
      return 'EXACT_AMOUNT';
    case SplitType.unknown:
      return null;
  }
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
      amountOwed: parseMoney(json['amount_owed']),
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
      totalAmount: parseMoney(json['total_amount']),
      splitType: splitTypeFromJson(json['split_type'] as String),
      expenseCategory: json['expense_category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      splits: (json['splits'] as List<dynamic>? ?? const [])
          .map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
