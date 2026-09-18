import '../../../core/network/api_client.dart';
import 'auth_session.dart';

/// Repositorio de autenticación. Mantiene `register` y `login` juntos
/// porque el flujo de la app los encadena (registrar y loguear en el
/// mismo paso) — si crecen mucho, sepáralos en dos archivos.
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return ApiClient.post('/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// Loguea y guarda el access_token en AuthSession. Lanza ApiException si
  /// la API responde con error (credenciales incorrectas, campo faltante, etc.)
  /// o si la respuesta no trae `access_token`.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/login', {
      'email': email,
      'password': password,
    });

    final token = response['access_token'] as String?;
    if (token == null) {
      throw ApiException(
        0,
        'La respuesta de login no incluyó un access_token.',
      );
    }

    AuthSession.instance.save(token);
    return token;
  }
}
