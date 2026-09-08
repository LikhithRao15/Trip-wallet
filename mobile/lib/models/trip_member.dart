class TripMember {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? joinedAt;

  TripMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'MEMBER',
      status: json['status'] ?? 'ACTIVE',
      joinedAt: json['joined_at']?.toString(),
    );
  }
}