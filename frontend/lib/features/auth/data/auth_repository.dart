import '../../../core/network/api_client.dart';
import 'auth_session.dart';
import 'user_profile.dart';

/// Repositorio de autenticación. Mantiene `register`, `login` y
/// `fetchProfile` juntos porque el flujo de la app los encadena — si
/// crecen mucho, sepáralos en archivos distintos.
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
      throw ApiException(0, 'La respuesta de login no incluyó un access_token.');
    }

    AuthSession.instance.saveToken(token);
    return token;
  }

  /// Trae el perfil del usuario logueado (GET /me) y lo guarda en
  /// AuthSession — necesitas llamarlo después de login() para tener
  /// disponible `AuthSession.instance.userId` en el resto de la app (ej.
  /// para saber si un gasto lo pagaste vos).
  Future<UserProfile> fetchProfile() async {
    final response = await ApiClient.get('/me', authenticated: true);
    final profile = UserProfile.fromJson(response as Map<String, dynamic>);
    AuthSession.instance.saveProfile(profile);
    return profile;
  }
}
