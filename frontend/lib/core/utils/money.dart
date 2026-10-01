/// Parseo tolerante de montos de dinero que llegan desde la API.
///
/// La spec declara los montos como STRING (para no perder precisión decimal,
/// igual que en `Expense.totalAmount` y `BalanceResponse.paid/owed`), pero
/// los schemas de *request* (`ExpenseCreate.total_amount`,
/// `SettlementCreate.amount`) aceptan número o string. O sea: el mismo
/// campo conceptual puede llegar en los dos tipos según de dónde venga, y
/// lo que hoy sólo llega como string no tiene garantía de seguir así.
///
/// Por eso esto degrada en vez de tirar. Con `double.parse(x as String)`, un
/// número donde se esperaba un string es un `TypeError` que tumba la pantalla
/// completa — la lista de gastos entera deja de renderizar porque UN campo de
/// UN gasto vino con otro tipo. Con `parseMoney` ese mismo dato vale 0 y el
/// resto de la lista se sigue viendo.
///
/// Es la diferencia entre "un número mal formado arruinó la pantalla" y "un
/// número mal formado se ve raro en una fila".
///
/// El 0 de retorno para un valor no parseable es deliberado y es la misma
/// decisión que ya tomaba `_toDouble` en `balance_summary.dart`, sólo que
/// ahora compartida: el parseo del dinero no debería tener dos
/// implementations con criterios distintos.
double parseMoney(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Igual que [parseMoney] pero para conteos enteros.
///
/// `GroupSettlementStatus.pendingCount` y `GroupBalanceSummary.pendingCount`
/// son `integer` en la spec, no string, pero el mismo criterio aplica por si
/// el backend los serializa como texto en alguna respuesta.
int parseCount(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
