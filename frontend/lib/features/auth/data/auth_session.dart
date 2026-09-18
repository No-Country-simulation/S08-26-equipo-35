/// Sesión de autenticación en memoria. Se pierde al cerrar la app — es
/// intencional por ahora (mantiene el alcance simple). Cuando quieras que
/// el usuario no tenga que loguearse cada vez que abre la app, reemplaza
/// el campo `_accessToken` por almacenamiento persistente, por ejemplo con
/// el paquete `flutter_secure_storage`.
class AuthSession {
  AuthSession._();
  static final instance = AuthSession._();

  String? _accessToken;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  void save(String accessToken) {
    _accessToken = accessToken;
  }

  void clear() {
    _accessToken = null;
  }
}
