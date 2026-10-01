import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/core/utils/query_params.dart';

void main() {
  final base = Uri.parse('https://api.example.com/api/v1/groups/g1/payments');

  group('withQueryParams', () {
    test('agrega los params que viene', () {
      final uri = withQueryParams(base, {'status': 'PENDING', 'limit': '100'});

      expect(uri.queryParameters['status'], 'PENDING');
      expect(uri.queryParameters['limit'], '100');
    });

    test('descarta los null (un filtro sin aplicar no viaja)', () {
      final uri = withQueryParams(base, {
        'status': null,
        'payer_id': 'u-1',
        'receiver_id': null,
      });

      expect(uri.queryParameters.containsKey('status'), isFalse);
      expect(uri.queryParameters.containsKey('receiver_id'), isFalse);
      expect(uri.queryParameters['payer_id'], 'u-1');
    });

    test('null o vacío deja la URL igual', () {
      expect(withQueryParams(base, null).toString(), base.toString());
      expect(withQueryParams(base, {}).toString(), base.toString());
      expect(withQueryParams(base, {'status': null}).toString(), base.toString());
    });

    test('no pisa los params que ya tenía la URL', () {
      final withQuery = Uri.parse(
        'https://api.example.com/api/v1/groups/g1/payments?existing=1',
      );

      final uri = withQueryParams(withQuery, {'status': 'PAID'});

      expect(uri.queryParameters['existing'], '1');
      expect(uri.queryParameters['status'], 'PAID');
    });

    test('url-encodea los valores (rompería concatenando a mano)', () {
      final uri = withQueryParams(base, {'status': 'PENDING&limit=999'});

      // El & del valor no puede cerrar el query y agregar un param falso.
      expect(uri.queryParameters['status'], 'PENDING&limit=999');
      expect(uri.queryParameters.containsKey('limit'), isFalse);
      expect(uri.toString(), contains('%26'));
    });
  });
}
