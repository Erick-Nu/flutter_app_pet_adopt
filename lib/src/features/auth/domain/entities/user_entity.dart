class UserEntity {
  final String id;
  final String email;
  final String? type; // 'adoptante' o 'fundacion' (lo llenaremos después)

  const UserEntity({
    required this.id,
    required this.email,
    this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}