class FirebaseUserRole {
  const FirebaseUserRole({
    required this.uid,
    required this.email,
    required this.role,
    required this.familyIds,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String role;
  final List<String> familyIds;
  final bool active;
  final Object? createdAt;
  final Object? updatedAt;

  bool get isSuperAdmin => role == 'superAdmin';

  factory FirebaseUserRole.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return FirebaseUserRole(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      familyIds: (data['familyIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      active: data['active'] == true,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }
}
