import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'user_profile.dart';

/// Sesión de autenticación con persistencia en `flutter_secure_storage`.
///
/// El token y el perfil se guardan cifrados en el almacenamiento seguro
/// del dispositivo (Android Keystore / iOS Keychain) y se restauran en
/// `AuthSession.init()`, que se llama en `main()` antes de `runApp` —
/// así al reabrir la app el usuario queda logueado sin pasar por
/// onboarding (el `SessionGate` valida el token contra `GET /me`).
///
/// Los getters siguen siendo síncronos (hay una caché en memoria) porque
/// `ApiClient._headers` lee `accessToken` sin awaits. Cada operación de
/// storage va en try/catch: si el almacenamiento seguro falla (ej.
/// navegador sin contexto seguro), la sesión sigue funcionando en
/// memoria igual que antes — solo se pierde la persistencia.
class AuthSession {
  AuthSession._();
  static final instance = AuthSession._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'sf_access_token';
  static const _profileKey = 'sf_profile';

  String? _accessToken;
  UserProfile? _profile;

  String? get accessToken => _accessToken;
  UserProfile? get profile => _profile;

  /// Atajos usados en toda la app para saber "quién soy yo" — ej. para
  /// comparar contra `payer_user_id` de un gasto y saber si lo pagaste vos.
  String? get userId => _profile?.userId;
  String? get userName => _profile?.name;

  bool get isAuthenticated => _accessToken != null;

  /// Restaura la sesión persistida (token + perfil) en la caché en
  /// memoria. Se llama una vez en `main()`, antes de `runApp`.
  Future<void> init() async {
    try {
      _accessToken = await _storage.read(key: _tokenKey);
      final rawProfile = await _storage.read(key: _profileKey);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        _profile = UserProfile.fromJson(jsonDecode(rawProfile) as Map<String, dynamic>);
      }
    } catch (_) {
      // Storage no disponible — la sesión queda vacía y el usuario
      // se loguea de nuevo, igual que con el comportamiento en memoria.
      _accessToken = null;
      _profile = null;
    }
  }

  Future<void> saveToken(String accessToken) async {
    _accessToken = accessToken;
    try {
      await _storage.write(key: _tokenKey, value: accessToken);
    } catch (_) {
      // Persistencia best-effort: en memoria ya quedó.
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    try {
      await _storage.write(key: _profileKey, value: jsonEncode({
        'user_id': profile.userId,
        'name': profile.name,
        'email': profile.email,
      }));
    } catch (_) {
      // Persistencia best-effort: en memoria ya quedó.
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _profile = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _profileKey);
    } catch (_) {
      // Best-effort: aunque el borrado falle, en memoria ya no hay sesión.
    }
  }
}
