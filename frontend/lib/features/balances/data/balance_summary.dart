import '../../../core/utils/money.dart';
import '../../groups/data/group_detail.dart';

/// Modelos de los endpoints `balance-summary`.
///
/// Montos de dinero: se parsean con `parseMoney` (ver `core/utils/money.dart`)
/// en el borde, una sola vez. Dentro de la app ya son números.
///
/// Todos los defaults son defensivos a propósito: si un campo viene
/// ausente o en un tipo inesperado se degrada a 0 / lista vacía en vez de
/// tirar. Home dibuja el balance de TODOS los grupos en una sola pantalla
/// — que un grupo mal formatado no deje la pantalla en blanco vale más
/// que un error ruidoso acá.
bool _toBool(dynamic value) => value == true;

List<T> _toList<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  final result = <T>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) result.add(parse(item));
  }
  return result;
}

/// `PerGroupUserSummary` — una fila de `per_group` en el resumen global.
class PerGroupUserSummary {
  const PerGroupUserSummary({
    required this.groupId,
    required this.groupName,
    required this.owed,
    required this.toReceive,
    required this.net,
    required this.pendingCount,
    required this.isSettled,
  });

  final String groupId;
  final String groupName;

  /// Lo que le debo a otros en ESTE grupo.
  final double owed;

  /// Lo que me deben en ESTE grupo.
  final double toReceive;

  /// Positivo = me deben; negativo = debo; cero = saldado.
  final double net;
  final int pendingCount;
  final bool isSettled;

  factory PerGroupUserSummary.fromJson(Map<String, dynamic> json) {
    return PerGroupUserSummary(
      groupId: json['group_id'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      owed: parseMoney(json['owed']),
      toReceive: parseMoney(json['to_receive']),
      net: parseMoney(json['net']),
      pendingCount: parseCount(json['pending_count']),
      isSettled: _toBool(json['is_settled']),
    );
  }
}

/// `UserGlobalSummaryResponse` — GET /api/v1/users/me/balance-summary.
///
/// Reemplaza el cálculo de balance en cliente que hacía Home (3 requests
/// por grupo + `calculateNetBalance`); ahora es UNA llamada.
class UserGlobalSummary {
  const UserGlobalSummary({
    required this.userId,
    required this.totalOwed,
    required this.totalToReceive,
    required this.net,
    required this.groupCount,
    required this.perGroup,
  });

  final String userId;
  final double totalOwed;
  final double totalToReceive;
  final double net;
  final int groupCount;
  final List<PerGroupUserSummary> perGroup;

  /// Índice por `group_id` para no recorrer `perGroup` una vez por grupo
  /// en Home. Vacío si el usuario no pertenece a ningún grupo.
  Map<String, PerGroupUserSummary> get byGroupId => {
        for (final g in perGroup) g.groupId: g,
      };

  factory UserGlobalSummary.fromJson(Map<String, dynamic> json) {
    return UserGlobalSummary(
      userId: json['user_id'] as String? ?? '',
      totalOwed: parseMoney(json['total_owed']),
      totalToReceive: parseMoney(json['total_to_receive']),
      net: parseMoney(json['net']),
      groupCount: parseCount(json['group_count']),
      perGroup: _toList(json['per_group'], PerGroupUserSummary.fromJson),
    );
  }
}

/// `GroupBalanceSummaryResponse` — GET /api/v1/groups/{id}/balance-summary.
///
/// A diferencia de `PerGroupUserSummary`, ÉSTE sí trae `memberCount` y el
/// desglose por miembro, así que sirve para las pantallas de detalle.
class GroupBalanceSummary {
  const GroupBalanceSummary({
    required this.groupId,
    required this.totalExpenses,
    required this.totalSettledAmount,
    required this.totalPendingAmount,
    required this.pendingCount,
    required this.memberCount,
    required this.isSettled,
    required this.balances,
    required this.suggestedTransfers,
  });

  final String groupId;
  final double totalExpenses;
  final double totalSettledAmount;
  final double totalPendingAmount;
  final int pendingCount;
  final int memberCount;
  final bool isSettled;
  final List<BalanceResponse> balances;

  /// Transferencias sugeridas por el backend (DebtResponse).
  final List<DebtResponse> suggestedTransfers;

  factory GroupBalanceSummary.fromJson(Map<String, dynamic> json) {
    return GroupBalanceSummary(
      groupId: json['group_id'] as String? ?? '',
      totalExpenses: parseMoney(json['total_expenses']),
      totalSettledAmount: parseMoney(json['total_settled_amount']),
      totalPendingAmount: parseMoney(json['total_pending_amount']),
      pendingCount: parseCount(json['pending_count']),
      memberCount: parseCount(json['member_count']),
      isSettled: _toBool(json['is_settled']),
      balances: _toList(json['balances'], BalanceResponse.fromJson),
      suggestedTransfers:
          _toList(json['suggested_transfers'], DebtResponse.fromJson),
    );
  }
}