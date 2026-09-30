import '../../../core/network/api_client.dart';
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

  Future<void> updateGroupName(String groupId, String groupName) async {
    await ApiClient.patch('/groups/$groupId', {'group_name': groupName}, authenticated: true);
  }

  // NEW: Delete group
  Future<void> deleteGroup(String groupId) async {
    await ApiClient.delete('/groups/$groupId', authenticated: true);
  }

  // ---- Settlement endpoints ----

  Future<List<BalanceResponse>> listBalances(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/balances', authenticated: true);
    if (response is! List<dynamic>) {
      return [];
    }
    return (response as List<dynamic>)
        .map((item) => BalanceResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DebtResponse>> listDebts(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/debts', authenticated: true);
    return _parseDebtsList(response);
  }

  Future<List<DebtResponse>> listMyDebts(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/debts/me', authenticated: true);
    return _parseDebtsList(response);
  }

  Future<List<DebtResponse>> listDebtsForUser(String groupId, String userId) async {
    final response = await ApiClient.get('/groups/$groupId/debts/user/$userId', authenticated: true);
    return _parseDebtsList(response);
  }

  /// Estos endpoints devuelven GroupDebtsResponse (objeto con `debts`
  /// adentro); se acepta también una lista plana por compatibilidad.
  static List<DebtResponse> _parseDebtsList(dynamic response) {
    dynamic items = response;
    if (response is Map<String, dynamic>) {
      items = response['debts'];
    }
    if (items is! List<dynamic>) {
      return [];
    }
    return items
        .map((item) => DebtResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /groups/{id}/settlements — alias de /debts; devuelve el bundle
  /// completo (balances + debts + is_settled) en una sola llamada. Es el
  /// que usan Balances y Group Details.
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

  Future<List<SettlementResponse>> listPayments(String groupId) async {
    final response = await ApiClient.get('/groups/$groupId/payments', authenticated: true);
    if (response is! List<dynamic>) {
      return [];
    }
    return (response as List<dynamic>)
        .map((item) => SettlementResponse.fromJson(item as Map<String, dynamic>))
        .toList();
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
    return SettlementResponse.fromJson(response as Map<String, dynamic>);
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
