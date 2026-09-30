# WebSocket de grupos

## Conexión

```text
WS /ws/groups/{group_id}?token=<JWT>
```

El token es el JWT de acceso obtenido en el login. La conexión solo se acepta si el token es válido y el usuario pertenece al grupo. Si falla la autenticación o la autorización, el handshake se rechaza con HTTP 403.

## Eventos

Cada evento usa este sobre JSON:

```json
{
  "type": "expense.created",
  "group_id": "uuid",
  "timestamp": "2026-09-29T12:00:00.000Z",
  "payload": {}
}
```

| Tipo | Cuándo se emite | Datos principales de `payload` |
|---|---|---|
| `expense.created` | Se crea un gasto | `expense_id`, `group_id`, `payer_user_id`, `title`, `total_amount`, `split_type` |
| `expense.updated` | Se actualiza un gasto | `expense_id`, `group_id`, `payer_user_id`, `title`, `total_amount`, `split_type` |
| `expense.deleted` | Se elimina un gasto | `expense_id`, `group_id` |
| `settlement.created` | Se registra un pago pendiente | `settlement_id`, `group_id`, pagador, receptor, monto y estado |
| `settlement.paid` | Un pago pasa a `PAID` | `settlement_id`, `group_id`, pagador, receptor, monto y estado |
| `settlement.cancelled` | Se cancela un pago pendiente | `settlement_id`, `group_id`, pagador, receptor, monto y estado |
| `balance.updated` | Cambian los balances por un gasto o un pago `PAID` | `group_id` |

Al recibir `balance.updated`, el cliente puede volver a consultar el balance del grupo. La cancelación de pagos `PAID` no está permitida por las reglas actuales; solo se cancelan pagos pendientes.

## Heartbeat

El cliente envía `{"type":"ping"}` cada 30 segundos. El servidor responde `{"type":"pong"}` y cierra una conexión que no reciba un ping durante 60 segundos.

## Reconexión y fallback

Si el socket se cierra, el cliente puede reintentar con backoff de 1, 2, 4, 8 segundos, aumentando hasta un máximo de 30 segundos. Si WebSocket o Redis no están disponibles, usar polling como fuente de estado:

```text
GET /api/v1/groups/{group_id}/expenses
GET /api/v1/groups/{group_id}/balances
```

Se recomienda consultar los gastos cada 10 segundos mientras el socket no esté conectado. Redis Pub/Sub no conserva mensajes durante una caída; el polling permite recuperar el estado actual.

## Ejemplo Flutter

Con `web_socket_channel`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

final uri = Uri.parse('$baseUrl/ws/groups/$groupId').replace(
  queryParameters: {'token': accessToken},
);
final channel = WebSocketChannel.connect(uri);

channel.stream.listen((message) {
  final event = jsonDecode(message as String) as Map<String, dynamic>;
  if (event['type'] == 'expense.created' ||
      event['type'] == 'expense.updated' ||
      event['type'] == 'expense.deleted' ||
      event['type'] == 'balance.updated') {
    // Actualizar el estado del grupo o volver a consultar la API.
  }
});

final heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
  channel.sink.add(jsonEncode({'type': 'ping'}));
});

// Al salir de la vista:
heartbeat.cancel();
await channel.sink.close();
```

`baseUrl` debe usar `ws://` en desarrollo local o `wss://` detrás de TLS. El token viaja en la URL; evitar registrar la query completa en logs.
