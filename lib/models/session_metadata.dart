class SessionMetadata {
  const SessionMetadata({
    required this.uid,
    required this.familyId,
    required this.role,
    required this.signedInAt,
    required this.expiresAt,
    required this.appVersion,
    required this.authMethod,
  });

  final String uid;
  final String familyId;
  final String role;
  final DateTime signedInAt;
  final DateTime? expiresAt;
  final String appVersion;
  final String authMethod;

  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(DateTime.now());
  }

  Map<String, Object?> toJson() => {
    'uid': uid,
    'familyId': familyId,
    'role': role,
    'signedInAt': signedInAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'appVersion': appVersion,
    'authMethod': authMethod,
  };

  factory SessionMetadata.fromJson(Map<String, Object?> json) {
    return SessionMetadata(
      uid: json['uid'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
      role: json['role'] as String? ?? 'viewer',
      signedInAt:
          DateTime.tryParse(json['signedInAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      appVersion: json['appVersion'] as String? ?? '',
      authMethod: json['authMethod'] as String? ?? '',
    );
  }
}
