import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/features/expenses/domain/equal_split.dart';

void main() {
  group('equalSplit', () {
    test('reparte en partes iguales cuando el total es divisible', () {
      final splits = equalSplit(100, ['a', 'b']);

      expect(splits.map((s) => s.amountOwed), [50.0, 50.0]);
    });

    test('el sobrante va a los primeros participantes', () {
      // 33.34 + 33.33 + 33.33 = 100 exacto (y no 33.33333333333333 x3)
      final splits = equalSplit(100, ['a', 'b', 'c']);

      expect(splits.map((s) => s.amountOwed), [33.34, 33.33, 33.33]);
    });

    test('la suma siempre es exacta, incluido un solo participante', () {
      for (final total in [100.0, 100.01, 1.01, 0.05, 33.33, 7.77]) {
        for (final n in [1, 2, 3, 6, 7]) {
          final ids = List.generate(n, (i) => 'u$i');
          final totalSplit = equalSplit(total, ids)
              .fold<double>(0, (sum, s) => sum + s.amountOwed);

          expect(
            (totalSplit - total).abs(),
            lessThanOrEqualTo(0.0000001),
            reason: 'total=$total n=$n -> suma=$totalSplit',
          );
        }
      }
    });

    test('ningún monto tiene más de 2 decimales', () {
      final splits = equalSplit(100, ['a', 'b', 'c']);

      for (final s in splits) {
        expect((s.amountOwed * 100).round() / 100, s.amountOwed);
      }
    });

    test('sin participantes devuelve lista vacía', () {
      expect(equalSplit(100, []), isEmpty);
    });
  });
}
