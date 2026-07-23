enum ServerOperationType {
  memberCreate('member.create'),
  memberUpdate('member.update'),
  memberSoftDelete('member.softDelete'),
  relationshipCreate('relationship.create'),
  relationshipUpdate('relationship.update'),
  relationshipDelete('relationship.delete'),
  familyTreeLinkCreate('familyTreeLink.create'),
  familyTreeLinkUpdate('familyTreeLink.update'),
  familyTreeLinkDelete('familyTreeLink.delete'),
  unknown('unknown');

  const ServerOperationType(this.wireName);
  final String wireName;

  static ServerOperationType parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => unknown,
  );
}

enum ServerOperationStatus {
  pending,
  processing,
  retryScheduled,
  completed,
  rejected,
  conflict,
  failed,
  unknown;

  static ServerOperationStatus parse(Object? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => unknown);

  bool get isTerminal =>
      this == completed ||
      this == rejected ||
      this == conflict ||
      this == failed;
}

enum LocalSubmissionStatus {
  pendingSubmission,
  submitting,
  submittedToServer,
  serverProcessing,
  completed,
  conflict,
  needsResolution,
  failed,
  unknown;

  static LocalSubmissionStatus parse(Object? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => unknown);
}

class ServerOperation {
  const ServerOperation({
    required this.operationId,
    required this.localOperationId,
    required this.idempotencyKey,
    required this.familyId,
    required this.type,
    required this.resourceType,
    required this.resourceId,
    required this.resourceKey,
    required this.resourceSequence,
    required this.baseVersion,
    required this.payload,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.attemptCount,
    required this.schemaVersion,
    this.nextAttemptAt,
    this.lockedAt,
    this.lockedBy,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.completedAt,
    this.resultVersion,
  });

  final String operationId;
  final String localOperationId;
  final String idempotencyKey;
  final String familyId;
  final ServerOperationType type;
  final String resourceType;
  final String resourceId;
  final String resourceKey;
  final int resourceSequence;
  final int baseVersion;
  final Map<String, dynamic> payload;
  final ServerOperationStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final DateTime? lockedAt;
  final String? lockedBy;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime? completedAt;
  final int? resultVersion;
  final int schemaVersion;

  factory ServerOperation.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      try {
        final converted = (value as dynamic)?.toDate();
        return converted is DateTime ? converted : null;
      } catch (_) {
        return null;
      }
    }

    int number(Object? value, [int fallback = 0]) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

    return ServerOperation(
      operationId: '${json['operationId'] ?? json['id'] ?? ''}',
      localOperationId: '${json['localOperationId'] ?? ''}',
      idempotencyKey: '${json['idempotencyKey'] ?? ''}',
      familyId: '${json['familyId'] ?? ''}',
      type: ServerOperationType.parse(json['type']),
      resourceType: '${json['resourceType'] ?? ''}',
      resourceId: '${json['resourceId'] ?? ''}',
      resourceKey: '${json['resourceKey'] ?? ''}',
      resourceSequence: number(json['resourceSequence']),
      baseVersion: number(json['baseVersion']),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      status: ServerOperationStatus.parse(json['status']),
      createdBy: '${json['createdBy'] ?? ''}',
      createdAt: date(json['createdAt']),
      updatedAt: date(json['updatedAt']),
      attemptCount: number(json['attemptCount']),
      nextAttemptAt: date(json['nextAttemptAt']),
      lockedAt: date(json['lockedAt']),
      lockedBy: json['lockedBy']?.toString(),
      lastErrorCode: json['lastErrorCode']?.toString(),
      lastErrorMessage: json['lastErrorMessage']?.toString(),
      completedAt: date(json['completedAt']),
      resultVersion: json['resultVersion'] == null
          ? null
          : number(json['resultVersion']),
      schemaVersion: number(json['schemaVersion'], 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'localOperationId': localOperationId,
    'idempotencyKey': idempotencyKey,
    'familyId': familyId,
    'type': type.wireName,
    'resourceType': resourceType,
    'resourceId': resourceId,
    'resourceKey': resourceKey,
    'resourceSequence': resourceSequence,
    'baseVersion': baseVersion,
    'payload': payload,
    'status': status.name,
    'createdBy': createdBy,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'attemptCount': attemptCount,
    if (nextAttemptAt != null)
      'nextAttemptAt': nextAttemptAt!.toIso8601String(),
    if (lockedAt != null) 'lockedAt': lockedAt!.toIso8601String(),
    if (lockedBy != null) 'lockedBy': lockedBy,
    if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
    if (lastErrorMessage != null) 'lastErrorMessage': lastErrorMessage,
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    if (resultVersion != null) 'resultVersion': resultVersion,
    'schemaVersion': schemaVersion,
  };
}
