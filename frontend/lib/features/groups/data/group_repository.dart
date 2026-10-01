import '../../../core/network/api_client.dart';
import '../../balances/data/balance_summary.dart';
import 'group.dart';
import 'group_detail.dart';

class GroupRepository {
  GroupRepository._();
  static final instance = GroupRepository._();

  Future<List<Group>> listGroups() async {
    final response = await ApiClient.get('/groups/list', authenticated: true);
    if (response is! List<dynamic>) {
      return [];
    }
    return response.map((item) => Group.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<GroupDetail> groupDetail(String groupId) async {
    final response = await ApiClient.get('/groups/detail/$groupId', authenticated: true);
    return GroupDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<Group> createGroup(String name) async {
    final response = await ApiClient.post('/groups/create', {'name': name}, authenticated: true);
    if (response['group_id'] == null) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return Group.fromJson(response);
  }

  /// Renombra el grupo. Atajo de `updateGroup` que sólo manda el nombre.
  Future<void> updateGroupName(String groupId, String groupName) {
    return updateGroup(groupId, groupName: groupName);
  }

  /// PATCH /groups/{id_group}. `UpdateGroup` tiene todos los campos
  /// opcionales, así que sólo se manda lo que se quiere cambiar: si se
  /// mandara `status: null` el backend podría pisar el estado con null.
  Future<void> updateGroup(
    String groupId, {
    String? groupName,
    GroupStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (groupName != null) body['group_name'] = groupName;
    if (status != null) body['status'] = status == GroupStatus.settled ? 'settled' : 'active';
    if (body.isEmpty) return;
    await ApiClient.patch('/groups/$groupId', body, authenticated: true);
  }

  // NEW: Delete group
  Future<void> deleteGroup(String groupId) async {
    await ApiClient.delete('/groups/$groupId', authenticated: true);
  }

  // ---- Member endpoints ----

  /// POST /groups/{id_group}/members — suma a un usuario al grupo.
  ///
  /// `AddGroupMemberRequest` acepta `user_id` **o** `email`, y ambos son
  /// opcionales en el schema, así que se manda sólo el que se pasó: mandarle
  /// la clave del que no se usó como `null` haría que el backend lo tomar
  /// como un valor explícito.
  Future<GroupMember> addMember(
    String groupId, {
    String? userId,
    String? email,
  }) async {
    if (userId == null && email == null) {
      throw ApiException(0, 'Se necesita un email o un user_id para agregar al miembro.');
    }
    final body = <String, dynamic>{};
    if (userId != null) body['user_id'] = userId;
    if (email != null) body['email'] = email;

    final response = await ApiClient.post(
      '/groups/$groupId/members',
      body,
      authenticated: true,
    );
    if (response['user_id'] == null) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return GroupMember.fromJson(response);
  }

  /// DELETE /groups/{id_group}/members/{user_id} — da de baja a un miembro.
  ///
  /// El backend puede rechazar (400/409) si el usuario tiene gastos o deudas
  /// pendientes en el grupo; el error se propaga como `ApiException` para que
  /// la UI muestre el mensaje real en vez de asumir que salió bien.
  Future<void> removeMember(String groupId, String userId) async {
    await ApiClient.delete(
      '/groups/$groupId/members/$userId',
      authenticated: true,
    );
  }

  // ---- Settlement endpoints ----

  Future<List<BalanceResponse>> listBalances(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/balances', authenticated: true);
    if (response is! List<dynamic>) {
      return [];
    }
    return response
        .map((item) => BalanceResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /groups/{id}/settlements — alias de /debts; devuelve el bundle
  /// completo (balances + debts + is_settled) en una sola llamada. Es el
  /// que usan Balances y Group Details.
  ///
  /// Cubre también a los tres endpoints de deudas por usuario que se
  /// borraron de acá (`/debts`, `/debts/me`, `/debts/user/{id}`): los tres
  /// responden el mismo `GroupDebtsResponse`, no una lista filtrada. Por
  /// schema no son "mis deudas" sino el bundle entero, así que el desglose
  /// entre deudas propias y de terceros (Balances) o el filtro por
  /// `debtor_user_id` (Group Details) se hacen en el cliente sobre `debts`.
  ///
  /// Si algún día el backend confirma que `/debts/me` sí devuelve sólo lo
  /// del usuario, el filtro en cliente se puede borrar y este método
  /// readaptarse.
  Future<GroupDebtsBundle> getSettlements(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/settlements', authenticated: true);
    if (response is! Map<String, dynamic>) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return GroupDebtsBundle.fromJson(response);
  }

  Future<GroupSettlementStatus> getSettlementStatus(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/settlements/status', authenticated: true);
    if (response is! Map<String, dynamic>) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return GroupSettlementStatus.fromJson(response);
  }

  /// GET /groups/{id}/balance-summary — resumen agregado del grupo: totales,
  /// conteo de miembros/pendientes, balances por miembro y transferencias
  /// sugeridas, todo en una sola llamada.
  Future<GroupBalanceSummary> getBalanceSummary(String groupId) async {
    final response = await ApiClient.get(
      '/groups/$groupId/balance-summary',
      authenticated: true,
    );
    if (response is! Map<String, dynamic>) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return GroupBalanceSummary.fromJson(response);
  }

  /// Historial de pagos del grupo.
  ///
  /// Los filtros van al servidor, no a un `where` en cliente. `status` solo
  /// acepta los valores del enum del backend (`PENDING`/`PAID`/`CANCELLED`);
  /// cualquier otro devuelve 400 con un mensaje que la API muestra tal cual.
  /// `limit` tiene default 50 server-side — la UI manda 100 (el máximo) para
  /// no truncar en silencio; más de 100 pagos requeriría paginar con
  /// `offset`, que la pantalla todavía no hace.
  Future<List<SettlementResponse>> listPayments(
    String groupId, {
    String? status,
    String? payerId,
    String? receiverId,
    int? limit,
    int? offset,
  }) async {
    final response = await ApiClient.get(
      '/groups/$groupId/payments',
      authenticated: true,
      query: {
        'status': status,
        'payer_id': payerId,
        'receiver_id': receiverId,
        'limit': limit?.toString(),
        'offset': offset?.toString(),
      },
    );
    if (response is! List<dynamic>) {
      return [];
    }
    return response
        .map((item) => SettlementResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Detalle de un pago puntual. Útil para refrescar antes de confirmar: la
  /// lista puede tener una copia vieja y otro usuario ya lo confirmó o
  /// canceló. 404 si el pago ya no existe.
  Future<SettlementResponse> getPayment(String groupId, String settlementId) async {
    final response = await ApiClient.get(
      '/groups/$groupId/payments/$settlementId',
      authenticated: true,
    );
    return SettlementResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<SettlementResponse> createPayment({
    required String groupId,
    required String receiverUserId,
    required double amount,
  }) async {
    final body = {
      'receiver_user_id': receiverUserId,
      'amount': amount,
    };
    final response = await ApiClient.post('/groups/$groupId/payments', body, authenticated: true);
    return SettlementResponse.fromJson(response);
  }

  /// Cancela/rechaza un pago PENDING (payer o receiver). La deuda vuelve a
  /// existir, así que el backend devuelve el settlement con status CANCELLED.
  Future<SettlementResponse> cancelSettlement(String settlementId) async {
    final response = await ApiClient.patch(
      '/payments/$settlementId/cancel',
      {},
      authenticated: true,
    );
    return SettlementResponse.fromJson(response);
  }

  /// Confirma un pago pendiente. La API devuelve el settlement ya saldado
  /// (status y fecha) — se propaga para poder refrescar la fila sin volver
  /// a pedir la lista entera.
  Future<SettlementResponse> paySettlement(String settlementId) async {
    final response = await ApiClient.patch(
      '/payments/$settlementId/pay',
      {},
      authenticated: true,
    );
    return SettlementResponse.fromJson(response);
  }
}
