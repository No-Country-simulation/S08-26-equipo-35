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

/// Respuesta de GET /detail/{id_group} — grupo + lista de miembros.
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
