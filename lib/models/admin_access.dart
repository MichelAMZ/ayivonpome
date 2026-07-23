class AdminAccess {
  const AdminAccess({
    this.currentAdminCode = '',
    this.lastChangedAt = '',
    this.nextChangeDueAt = '',
    this.rotationMonths = 3,
    this.enabled = false,
    this.requireCodeRotationReminder = false,
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
    currentAdminCode: '',
    lastChangedAt: json['lastChangedAt'] as String? ?? '',
    nextChangeDueAt: json['nextChangeDueAt'] as String? ?? '',
    rotationMonths: json['rotationMonths'] as int? ?? 3,
    enabled: false,
    requireCodeRotationReminder: false,
    codeHistory: const [],
  );

  Map<String, dynamic> toJson() => {
    'lastChangedAt': lastChangedAt,
    'nextChangeDueAt': nextChangeDueAt,
    'rotationMonths': rotationMonths,
    'enabled': enabled,
    'requireCodeRotationReminder': requireCodeRotationReminder,
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
