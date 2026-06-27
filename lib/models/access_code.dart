class AccessCode {
  const AccessCode({
    required this.id,
    required this.code,
    required this.label,
    required this.type,
    required this.role,
    this.familyCode = '',
    this.createdByAdminId = '',
    this.createdByName = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.expiresAt = '',
    this.maxUses,
    this.usedCount = 0,
    this.enabled = true,
    this.lastUsedAt = '',
    this.notes = '',
    this.previousCodeId = '',
    this.replacedByCodeId = '',
    this.regeneratedAt = '',
  });

  final String id;
  final String code;
  final String label;
  final String type;
  final String role;
  final String familyCode;
  final String createdByAdminId;
  final String createdByName;
  final String createdAt;
  final String updatedAt;
  final String expiresAt;
  final int? maxUses;
  final int usedCount;
  final bool enabled;
  final String lastUsedAt;
  final String notes;
  final String previousCodeId;
  final String replacedByCodeId;
  final String regeneratedAt;

  bool get isExpired {
    if (expiresAt.trim().isEmpty) return false;
    final date = DateTime.tryParse(expiresAt);
    return date != null && DateTime.now().isAfter(date);
  }

  bool get isImportant => role == 'superAdmin' || type == 'adminKpi';

  factory AccessCode.fromJson(Map<String, dynamic> json) => AccessCode(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    label: json['label'] as String? ?? '',
    type: json['type'] as String? ?? 'temporary',
    role: json['role'] as String? ?? 'viewer',
    familyCode: json['familyCode'] as String? ?? '',
    createdByAdminId: json['createdByAdminId'] as String? ?? '',
    createdByName: json['createdByName'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    expiresAt: json['expiresAt'] as String? ?? '',
    maxUses: json['maxUses'] as int?,
    usedCount: json['usedCount'] as int? ?? 0,
    enabled: json['enabled'] as bool? ?? true,
    lastUsedAt: json['lastUsedAt'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    previousCodeId: json['previousCodeId'] as String? ?? '',
    replacedByCodeId: json['replacedByCodeId'] as String? ?? '',
    regeneratedAt: json['regeneratedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'label': label,
    'type': type,
    'role': role,
    'familyCode': familyCode,
    'createdByAdminId': createdByAdminId,
    'createdByName': createdByName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'expiresAt': expiresAt,
    'maxUses': maxUses,
    'usedCount': usedCount,
    'enabled': enabled,
    'lastUsedAt': lastUsedAt,
    'notes': notes,
    'previousCodeId': previousCodeId,
    'replacedByCodeId': replacedByCodeId,
    'regeneratedAt': regeneratedAt,
  };

  AccessCode copyWith({
    String? id,
    String? code,
    String? label,
    String? type,
    String? role,
    String? familyCode,
    String? createdByAdminId,
    String? createdByName,
    String? createdAt,
    String? updatedAt,
    String? expiresAt,
    int? maxUses,
    bool clearMaxUses = false,
    int? usedCount,
    bool? enabled,
    String? lastUsedAt,
    String? notes,
    String? previousCodeId,
    String? replacedByCodeId,
    String? regeneratedAt,
  }) {
    return AccessCode(
      id: id ?? this.id,
      code: code ?? this.code,
      label: label ?? this.label,
      type: type ?? this.type,
      role: role ?? this.role,
      familyCode: familyCode ?? this.familyCode,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: clearMaxUses ? null : maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      enabled: enabled ?? this.enabled,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      notes: notes ?? this.notes,
      previousCodeId: previousCodeId ?? this.previousCodeId,
      replacedByCodeId: replacedByCodeId ?? this.replacedByCodeId,
      regeneratedAt: regeneratedAt ?? this.regeneratedAt,
    );
  }
}
