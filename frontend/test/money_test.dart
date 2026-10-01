import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/core/utils/money.dart';

/// Tests de `parseMoney` / `parseCount`.
///
/// Lo que se está protegiendo acá es la diferencia entre degradar y romper:
/// con `double.parse(x as String)`, un número donde la spec dice string es un
/// `TypeError` que tumba la pantalla completa. Con `parseMoney` el mismo dato
/// vale 0 y el resto de la lista se sigue viendo.
void main() {
  group('parseMoney', () {
    test('parsea el string que manda la spec para los montos', () {
      expect(parseMoney('12.34'), 12.34);
      expect(parseMoney('0'), 0.0);
      expect(parseMoney('100.00'), 100.0);
    });

    test('acepta num, que es como llegan los schemas de request', () {
      expect(parseMoney(12.34), 12.34);
      expect(parseMoney(0), 0.0);
      expect(parseMoney(-5.5), -5.5);
    });

    test('conserva los negativos — un balance en contra es un dato real', () {
      expect(parseMoney('-42.75'), -42.75);
      expect(parseMoney(-42.75), -42.75);
    });

    test('degrada a 0 en vez de tirar con un tipo inesperado', () {
      // El caso que antes rompía la pantalla: llega número donde se esperaba
      // string. Ahora no rompe.
      expect(parseMoney(null), 0.0);
      expect(parseMoney(true), 0.0);
      expect(parseMoney(<String, dynamic>{}), 0.0);
      expect(parseMoney([1, 2]), 0.0);
    });

    test('degrada a 0 con un string no numérico', () {
      expect(parseMoney(''), 0.0);
      expect(parseMoney('ayer'), 0.0);
      expect(parseMoney('12,34'), 0.0); // coma decimal
    });

    test('no tira con string numérico vacío de espacios', () {
      expect(parseMoney('  7.50  '), 7.50);
    });
  });

  group('parseCount', () {
    test('parsea int y string', () {
      expect(parseCount(3), 3);
      expect(parseCount('3'), 3);
    });

    test('trunca un double en vez de fallar', () {
      expect(parseCount(2.9), 2);
    });

    test('degrada a 0 con basura', () {
      expect(parseCount(null), 0);
      expect(parseCount('muchos'), 0);
    });
  });
}
