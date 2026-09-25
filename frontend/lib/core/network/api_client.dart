import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/data/auth_session.dart';

/// Error genérico para respuestas no-2xx o problemas de red.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.fieldErrors = const {}});

  /// 0 = no hubo respuesta del servidor (error de red/timeout).
  final int statusCode;
  final String message;

  /// Errores por campo, ej. {"password": "Debe tener minimo una MAYUSCULA"}.
  /// Viene de la lista `detail` que devuelve FastAPI/Pydantic — úsalo si
  /// más adelante quieres marcar el campo exacto en el formulario en vez
  /// de solo mostrar un SnackBar genérico.
  final Map<String, String> fieldErrors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP mínimo: toma la base URL de `API_URL` en el .env y expone
/// los métodos que la app necesita. Sin caché, sin interceptores, sin
/// reintentos — agrégalos aquí cuando los necesites, en un solo lugar.
class ApiClient {
  ApiClient._();

  static const _timeout = Duration(seconds: 30);

  static String get _baseUrl {
    final url = dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      throw StateError('API_URL no está definida en el .env');
    }
    return url;
  }

  // API_URL no lleva "/" final (según tu .env), así que cada `path` que
  // pases a post()/get() debe empezar con "/", ej. "/register".
  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = AuthSession.instance.accessToken;
      if (token == null) {
        throw StateError('No hay sesión activa (AuthSession.accessToken es null).');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET genérico. Devuelve `dynamic` porque algunos endpoints responden
  /// un objeto (`/me`) y otros un array (`/list`) — castea del lado del
  /// caller según lo que esperes.
  static Future<dynamic> get(String path, {bool authenticated = false}) async {
    late final http.Response response;
    try {
      response = await http.get(_uri(path), headers: _headers(authenticated: authenticated)).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        // Respuesta no-JSON — se ignora, decoded queda null.
      }
    }

    if (!isSuccess) {
      final errorBody = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      throw _buildException(response.statusCode, errorBody);
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body),
      ).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Respuesta no-JSON — se ignora, decoded queda vacío.
      }
    }

    if (!isSuccess) {
      throw _buildException(response.statusCode, decoded);
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    late final http.Response response;
    try {
      response = await http.put(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body),
      ).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (!isSuccess) {
      throw _buildException(response.statusCode, decoded);
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    late final http.Response response;
    try {
      response = await http.patch(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body),
      ).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (!isSuccess) {
      throw _buildException(response.statusCode, decoded);
    }

    return decoded;
  }

  static Future<dynamic> delete(String path, {bool authenticated = false}) async {
    late final http.Response response;
    try {
      response = await http.delete(
        _uri(path),
        headers: _headers(authenticated: authenticated),
      ).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccess) {
      Map<String, dynamic> decoded = {};
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }
      throw _buildException(response.statusCode, decoded);
    }

    return null;
  }

  /// Convierte el body de error a un ApiException legible. Soporta tres
  /// formatos: `{"detail": [ {loc, msg, ...}, ... ]}` (FastAPI/Pydantic,
  /// validación de campos), `{"detail": "texto"}` (FastAPI, error simple),
  /// y `{"message": "texto"}` (formato genérico, por si el backend cambia).
  static ApiException _buildException(int statusCode, Map<String, dynamic> decoded) {
    final detail = decoded['detail'];

    if (detail is List) {
      final fieldErrors = <String, String>{};
      for (final entry in detail) {
        if (entry is Map) {
          final loc = entry['loc'];
          final msg = entry['msg']?.toString() ?? 'Campo inválido';
          final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : 'general';
          fieldErrors[field] = msg;
        }
      }
      final message = fieldErrors.isNotEmpty
          ? fieldErrors.values.join('\n')
          : 'Error inesperado ($statusCode)';
      return ApiException(statusCode, message, fieldErrors: fieldErrors);
    }

    if (detail is String) {
      return ApiException(statusCode, detail);
    }

    final message = decoded['message'] as String? ?? 'Error inesperado ($statusCode)';
    return ApiException(statusCode, message);
  }
}
