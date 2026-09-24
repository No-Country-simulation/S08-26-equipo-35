/// Respuesta de `GET /api/v1/list` — un grupo, tal como lo devuelve la API.
/// Nota: la API todavía no incluye miembros, balance, ni ícono/color por
/// grupo. Ver GroupRepository/Home para cómo se cubren esos huecos por ahora.
class Group {
  const Group({
    required this.groupId,
    required this.groupName,
    required this.createdAt,
    required this.createdByUserId,
  });

  final String groupId;
  final String groupName;
  final DateTime createdAt;
  final String createdByUserId;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByUserId: json['created_by_user_id'] as String,
    );
  }
}
