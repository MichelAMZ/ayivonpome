class AuditLog {
  const AuditLog({
    required this.id,
    required this.date,
    required this.action,
    this.actorRole = '',
    this.adminId = '',
    this.personId = '',
    this.familyCode = '',
    this.description = '',
  });

  final String id;
  final String date;
  final String action;
  final String actorRole;
  final String adminId;
  final String personId;
  final String familyCode;
  final String description;

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        action: json['action'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? '',
        adminId: json['adminId'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        familyCode: json['familyCode'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'action': action,
        'actorRole': actorRole,
        'adminId': adminId,
        'personId': personId,
        'familyCode': familyCode,
        'description': description,
      };
}
