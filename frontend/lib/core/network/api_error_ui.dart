import 'package:flutter/material.dart';

import 'api_client.dart';

/// Traduce un error a un mensaje que no le mienta al usuario.
///
/// La distinción importa: `ApiClient` convierte TODO fallo de red/timeout en
/// `ApiException(0, 'No se pudo conectar con el servidor.')`, y los `catch (_)`
/// genéricos de las pantallas mostraban ese mismo texto para cualquier otra
/// cosa — incluyendo un 500 del backend y hasta un error de parseo de una
/// respuesta exitosa. Decirle a alguien "no se pudo conectar" cuando el
/// servidor explotó lo manda a reiniciar el router en vez de esperar o
/// reportar el bug.
///
/// - `0`        → no hubo respuesta: red/timeout. Sí es un problema de conexión.
/// - `>= 500`   → el backend falló. No es un problema de conexión.
/// - otro 4xx   → la API respondió con un mensaje; se muestra tal cual.
/// - no-Api     → respuesta inesperada (parseo). No es un problema de conexión.
String apiErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 0) return 'No se pudo conectar con el servidor.';
    if (error.statusCode >= 500) {
      return 'El servidor tuvo un error (${error.statusCode}). '
          'Probá de nuevo en un momento.';
    }
    return error.message;
  }
  return 'La respuesta del servidor no se pudo interpretar.';
}

/// Muestra un error de API en un SnackBar.
///
/// Loguea el error original para que el detalle (status + body) quede en
/// consola: la UI muestra un mensaje corto, pero la causa queda registrada.
void showApiError(BuildContext context, Object error) {
  debugPrint('[api] $error');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(apiErrorMessage(error))),
  );
}
