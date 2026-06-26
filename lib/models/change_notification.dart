class ChangeNotification {
  const ChangeNotification({
    required this.id,
    required this.personId,
    required this.personFullName,
    required this.action,
    required this.modifiedByAdminId,
    required this.modifiedByName,
    required this.modifiedAt,
    this.seenByCodes = const [],
    required this.message,
  });

  final String id;
  final String personId;
  final String personFullName;
  final String action;
  final String modifiedByAdminId;
  final String modifiedByName;
  final String modifiedAt;
  final List<String> seenByCodes;
  final String message;

  factory ChangeNotification.fromJson(Map<String, dynamic> json) =>
      ChangeNotification(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        personFullName: json['personFullName'] as String? ?? '',
        action: json['action'] as String? ?? '',
        modifiedByAdminId: json['modifiedByAdminId'] as String? ?? '',
        modifiedByName: json['modifiedByName'] as String? ?? '',
        modifiedAt: json['modifiedAt'] as String? ?? '',
        seenByCodes: List<String>.from(
          json['seenByCodes'] as List? ?? const [],
        ),
        message: json['message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'personFullName': personFullName,
    'action': action,
    'modifiedByAdminId': modifiedByAdminId,
    'modifiedByName': modifiedByName,
    'modifiedAt': modifiedAt,
    'seenByCodes': seenByCodes,
    'message': message,
  };

  ChangeNotification copyWith({List<String>? seenByCodes}) {
    return ChangeNotification(
      id: id,
      personId: personId,
      personFullName: personFullName,
      action: action,
      modifiedByAdminId: modifiedByAdminId,
      modifiedByName: modifiedByName,
      modifiedAt: modifiedAt,
      seenByCodes: seenByCodes ?? this.seenByCodes,
      message: message,
    );
  }
}
