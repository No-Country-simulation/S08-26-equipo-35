/// Respuesta de `GET /api/v1/me`.
class UserProfile {
  const UserProfile({required this.userId, required this.name, required this.email});

  final String userId;
  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
