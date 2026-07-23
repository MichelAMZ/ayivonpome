class SuperAdminRecovery {
  const SuperAdminRecovery({
    this.enabled = false,
    this.recoveryCode = '',
    this.lastUsedAt = '',
    this.lastResetAt = '',
    this.allowResetAllCodes = false,
  });

  final bool enabled;
  final String recoveryCode;
  final String lastUsedAt;
  final String lastResetAt;
  final bool allowResetAllCodes;

  factory SuperAdminRecovery.fromJson(Map<String, dynamic> json) =>
      SuperAdminRecovery(
        enabled: false,
        recoveryCode: '',
        lastUsedAt: json['lastUsedAt'] as String? ?? '',
        lastResetAt: json['lastResetAt'] as String? ?? '',
        allowResetAllCodes: false,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
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
