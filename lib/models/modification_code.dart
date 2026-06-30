class ModificationCode {
  const ModificationCode({
    required this.code,
    required this.label,
    this.createdByAdminId = '',
    this.expiresAt = '',
    this.maxUses,
    this.usedCount = 0,
    this.enabled = true,
  });

  final String code;
  final String label;
  final String createdByAdminId;
  final String expiresAt;
  final int? maxUses;
  final int usedCount;
  final bool enabled;

  bool get isExpired {
    if (expiresAt.trim().isEmpty) return false;
    final expires = DateTime.tryParse(expiresAt);
    return expires != null && DateTime.now().isAfter(expires);
  }

  bool get hasUsesRemaining => maxUses == null || usedCount < maxUses!;
  bool get isValid => enabled && !isExpired && hasUsesRemaining;

  factory ModificationCode.fromJson(Map<String, dynamic> json) =>
      ModificationCode(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        createdByAdminId: json['createdByAdminId'] as String? ?? '',
        expiresAt: json['expiresAt'] as String? ?? '',
        maxUses: json['maxUses'] as int?,
        usedCount: json['usedCount'] as int? ?? 0,
        enabled: json['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'code': code,
    'label': label,
    'createdByAdminId': createdByAdminId,
    'expiresAt': expiresAt,
    'maxUses': maxUses,
    'usedCount': usedCount,
    'enabled': enabled,
  };

  ModificationCode copyWith({
    String? code,
    String? label,
    String? createdByAdminId,
    String? expiresAt,
    int? maxUses,
    bool clearMaxUses = false,
    int? usedCount,
    bool? enabled,
  }) => ModificationCode(
    code: code ?? this.code,
    label: label ?? this.label,
    createdByAdminId: createdByAdminId ?? this.createdByAdminId,
    expiresAt: expiresAt ?? this.expiresAt,
    maxUses: clearMaxUses ? null : maxUses ?? this.maxUses,
    usedCount: usedCount ?? this.usedCount,
    enabled: enabled ?? this.enabled,
  );
}
