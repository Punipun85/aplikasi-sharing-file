class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '-',
      email: map['email'] as String? ?? '-',
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
    );
  }
}
