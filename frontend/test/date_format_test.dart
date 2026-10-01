import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/core/utils/date_format.dart';

/// Tests de `formatShortDate`.
///
/// Existían porque el formato cambió de "Jul 14, 2024" (mes primero, con
/// coma) a "14 jul 2024" (día primero, sin coma, que es la convención en
/// español). El orden de las partes no es cosmético: un string se puede
/// tener en un lugar esperando "14 jul" y en otro esperando "jul 14".
void main() {
  test('día primero, mes abreviado en español, sin coma', () {
    expect(formatShortDate(DateTime(2024, 7, 14)), '14 jul 2024');
  });

  test('los doce meses salen abreviados en español', () {
    const expected = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    for (var month = 1; month <= 12; month++) {
      final label = formatShortDate(DateTime(2026, month, 1));
      expect(label, '1 ${expected[month - 1]} 2026');
    }
  });

  test('no hay coma entre el día y el mes', () {
    // El formato inglés era "Jul 14, 2024"; la coma desapareció.
    expect(formatShortDate(DateTime(2024, 7, 14)), isNot(contains(',')));
  });

  test('el día no lleva cero a la izquierda', () {
    expect(formatShortDate(DateTime(2026, 3, 5)), '5 mar 2026');
  });

  test('formatea la fecha local, no la UTC', () {
    // Un DateTime con hora 23:00 local cruzaría de día al pasarlo a UTC y
    // mostraría la fecha equivocada. Por eso se formatea el `date` tal cual.
    final date = DateTime(2026, 12, 31, 23, 30);
    expect(formatShortDate(date), '31 dic 2026');
  });
}
