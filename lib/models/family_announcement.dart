class FamilyAnnouncementSettings {
  const FamilyAnnouncementSettings({
    this.birthdayPopupsEnabled = true,
    this.birthPopupsEnabled = true,
    this.birthdayMessage =
        'La grande famille te souhaite un joyeux anniversaire',
    this.birthMessage =
        'La grande famille accueille avec joie cette nouvelle naissance.',
    this.defaultImage = '',
  });

  final bool birthdayPopupsEnabled;
  final bool birthPopupsEnabled;
  final String birthdayMessage;
  final String birthMessage;
  final String defaultImage;

  factory FamilyAnnouncementSettings.fromJson(Map<String, dynamic> json) =>
      FamilyAnnouncementSettings(
        birthdayPopupsEnabled: json['birthdayPopupsEnabled'] as bool? ?? true,
        birthPopupsEnabled: json['birthPopupsEnabled'] as bool? ?? true,
        birthdayMessage:
            json['birthdayMessage'] as String? ??
            'La grande famille te souhaite un joyeux anniversaire',
        birthMessage:
            json['birthMessage'] as String? ??
            'La grande famille accueille avec joie cette nouvelle naissance.',
        defaultImage: json['defaultImage'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'birthdayPopupsEnabled': birthdayPopupsEnabled,
    'birthPopupsEnabled': birthPopupsEnabled,
    'birthdayMessage': birthdayMessage,
    'birthMessage': birthMessage,
    'defaultImage': defaultImage,
  };

  FamilyAnnouncementSettings copyWith({
    bool? birthdayPopupsEnabled,
    bool? birthPopupsEnabled,
    String? birthdayMessage,
    String? birthMessage,
    String? defaultImage,
  }) {
    return FamilyAnnouncementSettings(
      birthdayPopupsEnabled:
          birthdayPopupsEnabled ?? this.birthdayPopupsEnabled,
      birthPopupsEnabled: birthPopupsEnabled ?? this.birthPopupsEnabled,
      birthdayMessage: birthdayMessage ?? this.birthdayMessage,
      birthMessage: birthMessage ?? this.birthMessage,
      defaultImage: defaultImage ?? this.defaultImage,
    );
  }
}

class FamilyAnnouncementHistory {
  const FamilyAnnouncementHistory({
    required this.id,
    required this.type,
    required this.memberId,
    required this.message,
    required this.date,
    required this.createdAt,
    this.whatsappStatus = 'pending',
  });

  final String id;
  final String type;
  final String memberId;
  final String message;
  final String date;
  final String whatsappStatus;
  final String createdAt;

  factory FamilyAnnouncementHistory.fromJson(Map<String, dynamic> json) =>
      FamilyAnnouncementHistory(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        message: json['message'] as String? ?? '',
        date: json['date'] as String? ?? '',
        whatsappStatus: json['whatsappStatus'] as String? ?? 'pending',
        createdAt:
            json['createdAt'] as String? ?? json['date'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'memberId': memberId,
    'message': message,
    'date': date,
    'whatsappStatus': whatsappStatus,
    'createdAt': createdAt,
  };

  FamilyAnnouncementHistory copyWith({
    String? message,
    String? whatsappStatus,
    String? createdAt,
  }) {
    return FamilyAnnouncementHistory(
      id: id,
      type: type,
      memberId: memberId,
      message: message ?? this.message,
      date: date,
      whatsappStatus: whatsappStatus ?? this.whatsappStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
