class InfoNews {
  const InfoNews({
    required this.id,
    required this.title,
    required this.message,
    this.isActive = true,
    this.priority = 0,
    this.startAt = '',
    this.endAt = '',
    this.sendToContacts = false,
    this.createdAt = '',
    this.updatedAt = '',
    this.createdBy = '',
  });

  final String id;
  final String title;
  final String message;
  final bool isActive;
  final int priority;
  final String startAt;
  final String endAt;
  final bool sendToContacts;
  final String createdAt;
  final String updatedAt;
  final String createdBy;

  factory InfoNews.fromJson(Map<String, dynamic> json) => InfoNews(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    priority: json['priority'] as int? ?? 0,
    startAt: json['startAt'] as String? ?? '',
    endAt: json['endAt'] as String? ?? '',
    sendToContacts: json['sendToContacts'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    createdBy: json['createdBy'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'isActive': isActive,
    'priority': priority,
    'startAt': startAt,
    'endAt': endAt,
    'sendToContacts': sendToContacts,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'createdBy': createdBy,
  };

  InfoNews copyWith({
    String? id,
    String? title,
    String? message,
    bool? isActive,
    int? priority,
    String? startAt,
    String? endAt,
    bool? sendToContacts,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
  }) {
    return InfoNews(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      sendToContacts: sendToContacts ?? this.sendToContacts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class InfoNewsSendLog {
  const InfoNewsSendLog({
    required this.id,
    required this.infoNewsId,
    required this.contactPersonId,
    required this.contactName,
    required this.contactPhone,
    required this.date,
    this.createdAt = '',
    this.status = 'pending',
    this.error = '',
  });

  final String id;
  final String infoNewsId;
  final String contactPersonId;
  final String contactName;
  final String contactPhone;
  final String date;
  final String createdAt;
  final String status;
  final String error;

  factory InfoNewsSendLog.fromJson(Map<String, dynamic> json) =>
      InfoNewsSendLog(
        id: json['id'] as String? ?? '',
        infoNewsId: json['infoNewsId'] as String? ?? '',
        contactPersonId: json['contactPersonId'] as String? ?? '',
        contactName: json['contactName'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        date: json['date'] as String? ?? '',
        createdAt:
            json['createdAt'] as String? ?? json['date'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        error: json['error'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'infoNewsId': infoNewsId,
    'contactPersonId': contactPersonId,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'date': date,
    'createdAt': createdAt,
    'status': status,
    'error': error,
  };

  InfoNewsSendLog copyWith({
    String? status,
    String? error,
    String? date,
    String? createdAt,
  }) {
    return InfoNewsSendLog(
      id: id,
      infoNewsId: infoNewsId,
      contactPersonId: contactPersonId,
      contactName: contactName,
      contactPhone: contactPhone,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
