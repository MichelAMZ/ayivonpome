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
      role: normalizedRole(data['role']) ?? 'viewer',
      familyIds: readFamilyIds(data),
      active: readActive(data),
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

  static List<String> readFamilyIds(Map<String, dynamic> data) {
    final values = <String>{
      if (data['familyId'] is String) (data['familyId'] as String).trim(),
      if (data['familyIds'] is List)
        ...(data['familyIds'] as List).whereType<String>().map(
          (value) => value.trim(),
        ),
    }..removeWhere((value) => value.isEmpty);
    return values.toList(growable: false);
  }

  static bool readActive(Map<String, dynamic> data) {
    if (data['active'] is bool) return data['active'] == true;
    if (data['isActive'] is bool) return data['isActive'] == true;
    if (data['enabled'] is bool) return data['enabled'] == true;
    return data['status'] is String &&
        (data['status'] as String).trim().toLowerCase() == 'active';
  }

  static String? normalizedRole(Object? value) {
    final role = value is String ? value.trim() : '';
    return switch (role) {
      'superAdmin' => 'superAdmin',
      'familyAdmin' || 'admin' => 'admin',
      'editor' => 'editor',
      'viewer' => 'viewer',
      _ => null,
    };
  }
}
