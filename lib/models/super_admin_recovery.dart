class SuperAdminRecovery {
  const SuperAdminRecovery({
    this.enabled = true,
    this.recoveryCode = 'Aziangbédévi2026!',
    this.lastUsedAt = '',
    this.lastResetAt = '',
    this.allowResetAllCodes = true,
  });

  final bool enabled;
  final String recoveryCode;
  final String lastUsedAt;
  final String lastResetAt;
  final bool allowResetAllCodes;

  factory SuperAdminRecovery.fromJson(Map<String, dynamic> json) =>
      SuperAdminRecovery(
        enabled: json['enabled'] as bool? ?? true,
        recoveryCode: json['recoveryCode'] as String? ?? 'Aziangbédévi2026!',
        lastUsedAt: json['lastUsedAt'] as String? ?? '',
        lastResetAt: json['lastResetAt'] as String? ?? '',
        allowResetAllCodes: json['allowResetAllCodes'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'recoveryCode': recoveryCode,
    'lastUsedAt': lastUsedAt,
    'lastResetAt': lastResetAt,
    'allowResetAllCodes': allowResetAllCodes,
  };

  SuperAdminRecovery copyWith({
    bool? enabled,
    String? recoveryCode,
    String? lastUsedAt,
    String? lastResetAt,
    bool? allowResetAllCodes,
  }) {
    return SuperAdminRecovery(
      enabled: enabled ?? this.enabled,
      recoveryCode: recoveryCode ?? this.recoveryCode,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      allowResetAllCodes: allowResetAllCodes ?? this.allowResetAllCodes,
    );
  }
}
