class AdminAccess {
  const AdminAccess({
    this.currentAdminCode = 'ayivonvi2026',
    this.lastChangedAt = '2026-06-26T00:00:00',
    this.nextChangeDueAt = '2026-09-26T00:00:00',
    this.rotationMonths = 3,
    this.enabled = true,
    this.requireCodeRotationReminder = true,
    this.codeHistory = const [],
  });

  final String currentAdminCode;
  final String lastChangedAt;
  final String nextChangeDueAt;
  final int rotationMonths;
  final bool enabled;
  final bool requireCodeRotationReminder;
  final List<AdminCodeHistory> codeHistory;

  factory AdminAccess.fromJson(Map<String, dynamic> json) => AdminAccess(
    currentAdminCode: json['currentAdminCode'] as String? ?? 'ayivonvi2026',
    lastChangedAt: json['lastChangedAt'] as String? ?? '2026-06-26T00:00:00',
    nextChangeDueAt:
        json['nextChangeDueAt'] as String? ?? '2026-09-26T00:00:00',
    rotationMonths: json['rotationMonths'] as int? ?? 3,
    enabled: json['enabled'] as bool? ?? true,
    requireCodeRotationReminder:
        json['requireCodeRotationReminder'] as bool? ?? true,
    codeHistory: (json['codeHistory'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => AdminCodeHistory.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'currentAdminCode': currentAdminCode,
    'lastChangedAt': lastChangedAt,
    'nextChangeDueAt': nextChangeDueAt,
    'rotationMonths': rotationMonths,
    'enabled': enabled,
    'requireCodeRotationReminder': requireCodeRotationReminder,
    'codeHistory': codeHistory.map((item) => item.toJson()).toList(),
  };

  AdminAccess copyWith({
    String? currentAdminCode,
    String? lastChangedAt,
    String? nextChangeDueAt,
    int? rotationMonths,
    bool? enabled,
    bool? requireCodeRotationReminder,
    List<AdminCodeHistory>? codeHistory,
  }) {
    return AdminAccess(
      currentAdminCode: currentAdminCode ?? this.currentAdminCode,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      nextChangeDueAt: nextChangeDueAt ?? this.nextChangeDueAt,
      rotationMonths: rotationMonths ?? this.rotationMonths,
      enabled: enabled ?? this.enabled,
      requireCodeRotationReminder:
          requireCodeRotationReminder ?? this.requireCodeRotationReminder,
      codeHistory: codeHistory ?? this.codeHistory,
    );
  }
}

class AdminCodeHistory {
  const AdminCodeHistory({
    required this.code,
    required this.createdAt,
    this.expiredAt = '',
    this.changedByAdminId = '',
  });

  final String code;
  final String createdAt;
  final String expiredAt;
  final String changedByAdminId;

  factory AdminCodeHistory.fromJson(Map<String, dynamic> json) =>
      AdminCodeHistory(
        code: json['code'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        expiredAt: json['expiredAt'] as String? ?? '',
        changedByAdminId: json['changedByAdminId'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'code': code,
    'createdAt': createdAt,
    'expiredAt': expiredAt,
    'changedByAdminId': changedByAdminId,
  };
}
