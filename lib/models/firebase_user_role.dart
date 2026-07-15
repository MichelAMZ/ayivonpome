class FirebaseUserRole {
  const FirebaseUserRole({
    required this.uid,
    required this.email,
    required this.role,
    required this.familyIds,
    required this.active,
    this.authMethod = '',
    this.accessCodeId = '',
    this.deviceFingerprintHash = '',
    this.lastAuthenticatedAt,
    this.sessionExpiresAt,
    this.revokedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String role;
  final List<String> familyIds;
  final bool active;
  final String authMethod;
  final String accessCodeId;
  final String deviceFingerprintHash;
  final Object? lastAuthenticatedAt;
  final Object? sessionExpiresAt;
  final Object? revokedAt;
  final Object? createdAt;
  final Object? updatedAt;

  bool get isSuperAdmin => role == 'superAdmin';
  bool get isAccessCodeSession => authMethod == 'accessCode';

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
      authMethod: data['authMethod'] as String? ?? '',
      accessCodeId: data['accessCodeId'] as String? ?? '',
      deviceFingerprintHash: data['deviceFingerprintHash'] as String? ?? '',
      lastAuthenticatedAt: data['lastAuthenticatedAt'],
      sessionExpiresAt: data['sessionExpiresAt'],
      revokedAt: data['revokedAt'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }
}
