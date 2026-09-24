import 'user_profile.dart';

/// Sesión de autenticación en memoria. Se pierde al cerrar la app — es
/// intencional por ahora (mantiene el alcance simple). Cuando quieras que
/// el usuario no tenga que loguearse cada vez que abre la app, reemplaza
/// el almacenamiento en memoria por algo persistente, por ejemplo con el
/// paquete `flutter_secure_storage`.
class AuthSession {
  AuthSession._();
  static final instance = AuthSession._();

  String? _accessToken;
  UserProfile? _profile;

  String? get accessToken => _accessToken;
  UserProfile? get profile => _profile;

  /// Atajos usados en toda la app para saber "quién soy yo" — ej. para
  /// comparar contra `payer_user_id` de un gasto y saber si lo pagaste vos.
  String? get userId => _profile?.userId;
  String? get userName => _profile?.name;

  bool get isAuthenticated => _accessToken != null;

  void saveToken(String accessToken) {
    _accessToken = accessToken;
  }

  void saveProfile(UserProfile profile) {
    _profile = profile;
  }

  void clear() {
    _accessToken = null;
    _profile = null;
  }
}
