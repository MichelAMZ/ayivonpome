import 'sync_diagnostic.dart';
import 'sync_state.dart';

class SyncIncident {
  const SyncIncident({
    required this.id,
    required this.familyId,
    required this.operationType,
    required this.collectionName,
    required this.documentId,
    required this.errorCode,
    required this.safeMessage,
    required this.technicalMessage,
    required this.attemptCount,
    required this.firstOccurredAt,
    required this.lastOccurredAt,
    required this.status,
    required this.severity,
    required this.sourceOperationId,
    this.userId = '',
    this.userEmail = '',
    this.emailNotificationSent = false,
    this.whatsappNotificationSent = false,
    this.resolvedAt = '',
    this.resolvedBy = '',
  });

  final String id;
  final String familyId;
  final String userId;
  final String userEmail;
  final String operationType;
  final String collectionName;
  final String documentId;
  final String errorCode;
  final String safeMessage;
  final String technicalMessage;
  final int attemptCount;
  final String firstOccurredAt;
  final String lastOccurredAt;
  final String status;
  final String severity;
  final bool emailNotificationSent;
  final bool whatsappNotificationSent;
  final String resolvedAt;
  final String resolvedBy;
  final String sourceOperationId;

  factory SyncIncident.fromPendingItem(
    PendingSyncItem item, {
    required String familyId,
    String userId = '',
    String userEmail = '',
  }) {
    final diagnostic = SyncOperationDiagnostic.fromItem(
      item,
      fallbackFamilyId: familyId,
    );
    final errorCode = _errorCode(item.lastError);
    final severity = errorCode == 'permission-denied' || item.retryCount >= 3
        ? 'critical'
        : 'warning';
    final now = DateTime.now().toIso8601String();
    final id = [
      diagnostic.familyId,
      diagnostic.collection,
      diagnostic.documentId,
      diagnostic.action,
      errorCode,
    ].map(_sanitizeIdPart).join('_');

    return SyncIncident(
      id: id,
      familyId: diagnostic.familyId,
      userId: userId,
      userEmail: userEmail,
      operationType: diagnostic.action,
      collectionName: diagnostic.collection,
      documentId: diagnostic.documentId,
      errorCode: errorCode,
      safeMessage: 'Echec de synchronisation',
      technicalMessage: item.lastError,
      attemptCount: item.retryCount,
      firstOccurredAt: item.createdAt.isEmpty ? now : item.createdAt,
      lastOccurredAt: item.updatedAt.isEmpty ? now : item.updatedAt,
      status: switch (item.status) {
        'inProgress' => 'inProgress',
        'resolved' => 'resolved',
        _ => 'new',
      },
      severity: severity,
      sourceOperationId: item.id,
    );
  }

  Map<String, dynamic> toFirestoreUpdate() => {
    'familyId': familyId,
    if (userId.isNotEmpty) 'userId': userId,
    if (userEmail.isNotEmpty) 'userEmail': userEmail,
    'operationType': operationType,
    'collectionName': collectionName,
    'documentId': documentId,
    'errorCode': errorCode,
    'safeMessage': safeMessage,
    'technicalMessage': technicalMessage,
    'attemptCount': attemptCount,
    'lastOccurredAtClient': lastOccurredAt,
    'status': status,
    'severity': severity,
    'emailNotificationSent': emailNotificationSent,
    'whatsappNotificationSent': whatsappNotificationSent,
    'resolvedAt': resolvedAt.isEmpty ? null : resolvedAt,
    'resolvedBy': resolvedBy.isEmpty ? null : resolvedBy,
  };

  static String _errorCode(String value) {
    if (value.contains('permission-denied')) return 'permission-denied';
    if (value.contains('unauthenticated')) return 'unauthenticated';
    if (value.contains('unavailable')) return 'unavailable';
    if (value.contains('failed-precondition')) return 'failed-precondition';
    if (value.contains('not-found')) return 'not-found';
    return 'sync-error';
  }

  static String _sanitizeIdPart(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]+'),
      '-',
    );
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}
