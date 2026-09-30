enum GroupStatus { active, settled }

class GroupMember {
  const GroupMember({required this.userId, required this.joinedAt});

  final String userId;
  final DateTime joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

/// Respuesta de GET /groups/detail/{id_group} — grupo + lista de miembros.
class GroupDetail {
  const GroupDetail({
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.createdAt,
    required this.members,
  });

  final String groupId;
  final String groupName;
  final GroupStatus status;
  final DateTime createdAt;
  final List<GroupMember> members;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      status: (json['status'] as String) == 'settled' ? GroupStatus.settled : GroupStatus.active,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: (json['members'] as List<dynamic>)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Settlement models (from API schemas)

// BalanceResponse: balance por usuario en un grupo
class BalanceResponse {
  const BalanceResponse({
    required this.userId,
    required this.name,
    required this.paid,
    required this.owed,
    required this.netBalance,
  });

  final String userId;
  final String name;
  final String paid;
  final String owed;
  final String netBalance;

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      paid: json['paid'] as String,
      owed: json['owed'] as String,
      netBalance: json['net_balance'] as String,
    );
  }
}

// DebtResponse: deuda entre dos usuarios
class DebtResponse {
  const DebtResponse({
    required this.debtorUserId,
    required this.debtorName,
    required this.creditorUserId,
    required this.creditorName,
    required this.amount,
    required this.status,
    required this.expenses,
  });

  final String debtorUserId;
  final String debtorName;
  final String creditorUserId;
  final String creditorName;
  final String amount;
  final String status;
  final List<DebtExpenseBreakdown> expenses;

  factory DebtResponse.fromJson(Map<String, dynamic> json) {
    return DebtResponse(
      debtorUserId: json['debtor_user_id'] as String,
      debtorName: json['debtor_name'] as String,
      creditorUserId: json['creditor_user_id'] as String,
      creditorName: json['creditor_name'] as String,
      amount: json['amount'] as String,
      status: json['status'] as String,
      expenses: (json['expenses'] as List<dynamic>? ?? const [])
          .map((e) => DebtExpenseBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// DebtExpenseBreakdown: desglose de gastos en una deuda
class DebtExpenseBreakdown {
  const DebtExpenseBreakdown({
    required this.expenseId,
    required this.title,
    required this.expenseCategory,
    required this.amount,
  });

  final String expenseId;
  final String title;
  final String expenseCategory;
  final String amount;

  factory DebtExpenseBreakdown.fromJson(Map<String, dynamic> json) {
    return DebtExpenseBreakdown(
      expenseId: json['expense_id'] as String,
      title: json['title'] as String,
      expenseCategory: json['expense_category'] as String,
      amount: json['amount'] as String,
    );
  }
}

// GroupSettlementStatus: estado de asentamiento de un grupo
class GroupSettlementStatus {
  const GroupSettlementStatus({
    required this.groupId,
    required this.isSettled,
    required this.pendingCount,
    required this.totalPendingAmount,
    required this.debts,
  });

  final String groupId;
  final bool isSettled;
  final int pendingCount;
  final String totalPendingAmount;
  final List<DebtResponse> debts;

  factory GroupSettlementStatus.fromJson(Map<String, dynamic> json) {
    return GroupSettlementStatus(
      groupId: json['group_id'] as String,
      isSettled: json['is_settled'] as bool,
      pendingCount: (json['pending_count'] as num).toInt(),
      totalPendingAmount: json['total_pending_amount'] as String,
      debts: (json['debts'] as List<dynamic>? ?? const [])
          .map((d) => DebtResponse.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

// SettlementResponse: respuesta de un pago individual
class SettlementResponse {
  const SettlementResponse({
    required this.settlementId,
    required this.groupId,
    required this.payerUserId,
    required this.receiverUserId,
    required this.amount,
    required this.status,
    required this.settledAt,
  });

  final String settlementId;
  final String groupId;
  final String payerUserId;
  final String receiverUserId;
  final String amount;
  final String status;
  final DateTime settledAt;

  factory SettlementResponse.fromJson(Map<String, dynamic> json) {
    return SettlementResponse(
      settlementId: json['settlement_id'] as String,
      groupId: json['group_id'] as String,
      payerUserId: json['payer_user_id'] as String,
      receiverUserId: json['receiver_user_id'] as String,
      amount: json['amount'] as String,
      status: json['status'] as String,
      settledAt: DateTime.parse(json['settled_at'] as String),
    );
  }
}

// GroupDebtsBundle: respuesta de GroupDebtsResponse — GET /groups/{id}/debts,
// /debts/me, /debts/user/{id} y /settlements devuelven balances + deudas +
// flag del grupo agrupados en un solo objeto.
class GroupDebtsBundle {
  const GroupDebtsBundle({
    required this.groupId,
    required this.balances,
    required this.debts,
    required this.isSettled,
  });

  final String groupId;
  final List<BalanceResponse> balances;
  final List<DebtResponse> debts;
  final bool isSettled;

  factory GroupDebtsBundle.fromJson(Map<String, dynamic> json) {
    return GroupDebtsBundle(
      groupId: json['group_id'] as String,
      balances: (json['balances'] as List<dynamic>? ?? const [])
          .map((item) => BalanceResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      debts: (json['debts'] as List<dynamic>? ?? const [])
          .map((item) => DebtResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      isSettled: json['is_settled'] as bool? ?? false,
    );
  }
}
