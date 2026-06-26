class ModificationHistory {
  const ModificationHistory({
    required this.id,
    required this.personId,
    required this.personFullName,
    required this.action,
    required this.modifiedByAdminId,
    required this.modifiedByName,
    required this.modifiedAt,
    required this.details,
    required this.expiresAt,
  });

  final String id;
  final String personId;
  final String personFullName;
  final String action;
  final String modifiedByAdminId;
  final String modifiedByName;
  final String modifiedAt;
  final String details;
  final String expiresAt;

  factory ModificationHistory.fromJson(Map<String, dynamic> json) =>
      ModificationHistory(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        personFullName: json['personFullName'] as String? ?? '',
        action: json['action'] as String? ?? '',
        modifiedByAdminId: json['modifiedByAdminId'] as String? ?? '',
        modifiedByName: json['modifiedByName'] as String? ?? '',
        modifiedAt: json['modifiedAt'] as String? ?? '',
        details: json['details'] as String? ?? '',
        expiresAt: json['expiresAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'personFullName': personFullName,
    'action': action,
    'modifiedByAdminId': modifiedByAdminId,
    'modifiedByName': modifiedByName,
    'modifiedAt': modifiedAt,
    'details': details,
    'expiresAt': expiresAt,
  };
}
