/// Reparto de un monto en partes iguales que suman **exactamente** el total.
///
/// Por qué no alcanza con `total / n`: al mandar los splits explícitos al
/// backend, `100 / 3` en punto flotante da `33.33333333333333` y la suma de
/// las 3 partes es `99.99999999999999`, no `100`. Con 2 decimales limpios
/// (33.34 + 33.33 + 33.33) la suma es exacta y cada parte es un monto válido.
///
/// Se reparte en centavos con el método del resto mayor: se le da a cada
/// participante `cents ~/ n` centavos y los `cents % n` centavos sobrantes se
/// distribuyen de a uno entre los primeros. Así nadie paga de más ni de menos.
typedef Split = ({String userId, double amountOwed});

List<Split> equalSplit(double total, List<String> memberIds) {
  if (memberIds.isEmpty) return const [];
  final cents = (total * 100).round();
  final base = cents ~/ memberIds.length;
  final remainder = cents - base * memberIds.length;
  return [
    for (var i = 0; i < memberIds.length; i++)
      (
        userId: memberIds[i],
        amountOwed: (base + (i < remainder ? 1 : 0)) / 100,
      ),
  ];
}
