import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_state.dart';

class SyncOperationDiagnostic {
  const SyncOperationDiagnostic({
    required this.localId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.collection,
    required this.documentId,
    required this.familyId,
    this.firebaseCode = '',
    this.firebaseMessage = '',
  });

  final String localId;
  final String action;
  final String entityType;
  final String entityId;
  final String collection;
  final String documentId;
  final String familyId;
  final String firebaseCode;
  final String firebaseMessage;

  factory SyncOperationDiagnostic.fromItem(
    PendingSyncItem item, {
    required String fallbackFamilyId,
    FirebaseException? firebaseException,
  }) {
    final collection = switch (item.entityType) {
      'person' => 'members',
      'marriage' => 'relationships',
      'familyLink' => 'family_tree_links',
      'notification' => 'notifications',
      'activityLog' => 'activity_logs',
      'family' => 'families',
      _ => item.entityType,
    };
    final familyId =
        item.payload['familyId'] as String? ??
        item.payload['familyCode'] as String? ??
        fallbackFamilyId;

    return SyncOperationDiagnostic(
      localId: item.id,
      action: item.action,
      entityType: item.entityType,
      entityId: item.entityId,
      collection: collection,
      documentId: item.entityId,
      familyId: familyId,
      firebaseCode: firebaseException?.code ?? '',
      firebaseMessage: firebaseException?.message ?? '',
    );
  }

  String get target => '$collection/$documentId';

  String get failureSummary {
    final code = firebaseCode.isEmpty ? 'sync-error' : firebaseCode;
    final message = firebaseMessage.trim();
    if (message.isEmpty) return '$code sur $target';
    return '$code sur $target - $message';
  }

  String get operationSummary {
    return 'localId=$localId action=$action entity=$entityType:$entityId '
        'collection=$collection documentId=$documentId familyId=$familyId';
  }
}
