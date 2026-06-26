class FamilyNotification {
  const FamilyNotification({
    required this.id,
    this.personId = '',
    this.targetPersonId = '',
    this.type = 'customMessage',
    this.channel = 'local',
    this.title = '',
    this.message = '',
    this.scheduledDate = '',
    this.status = 'pending',
    this.createdAt = '',
  });

  final String id;
  final String personId;
  final String targetPersonId;
  final String type;
  final String channel;
  final String title;
  final String message;
  final String scheduledDate;
  final String status;
  final String createdAt;

  factory FamilyNotification.fromJson(Map<String, dynamic> json) =>
      FamilyNotification(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        targetPersonId: json['targetPersonId'] as String? ?? '',
        type: json['type'] as String? ?? 'customMessage',
        channel: json['channel'] as String? ?? 'local',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        scheduledDate: json['scheduledDate'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'targetPersonId': targetPersonId,
        'type': type,
        'channel': channel,
        'title': title,
        'message': message,
        'scheduledDate': scheduledDate,
        'status': status,
        'createdAt': createdAt,
      };

  FamilyNotification copyWith({
    String? id,
    String? personId,
    String? targetPersonId,
    String? type,
    String? channel,
    String? title,
    String? message,
    String? scheduledDate,
    String? status,
    String? createdAt,
  }) {
    return FamilyNotification(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      targetPersonId: targetPersonId ?? this.targetPersonId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
