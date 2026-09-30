import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/core/network/api_client.dart';
import 'package:splitflow/core/network/api_error_ui.dart';

void main() {
  group('apiErrorMessage', () {
    test('statusCode 0 SÍ es un problema de conexión', () {
      final e = ApiException(0, 'No se pudo conectar con el servidor.');

      expect(apiErrorMessage(e), 'No se pudo conectar con el servidor.');
    });

    test('un 5xx no se reporta como problema de conexión', () {
      // Este es el caso real: el backend devuelve
      // {"detail":"Error al crear el gasto"} con status 500.
      final e = ApiException(500, 'Error al crear el gasto');

      final message = apiErrorMessage(e);

      expect(message, contains('El servidor tuvo un error (500)'));
      expect(message, isNot(contains('conectar')));
    });

    test('un 4xx muestra el mensaje de la API tal cual', () {
      final e = ApiException(400, 'Credenciales incorrectas');

      expect(apiErrorMessage(e), 'Credenciales incorrectas');
    });

    test('un 422 muestra los errores de campo que arma ApiClient', () {
      final e = ApiException(
        422,
        'Debe tener minimo una MAYUSCULA',
        fieldErrors: {'password': 'Debe tener minimo una MAYUSCULA'},
      );

      expect(apiErrorMessage(e), 'Debe tener minimo una MAYUSCULA');
    });

    test('un error de parseo no se reporta como conexión', () {
      // p. ej. jsonDecode fallando o un cast null a String al mapear
      final message = apiErrorMessage(const FormatException('bad json'));

      expect(message, isNot(contains('conectar')));
    });
  });
}
