import '../models/sync_state.dart';

enum ConflictResolutionChoice { keepLocal, keepRemote, mergeManually }

enum ConflictRecommendation {
  localNewer,
  remoteNewer,
  manualReview,
  noConflict,
}

class ConflictResolutionService {
  const ConflictResolutionService();

  ConflictRecommendation compare({
    required String localUpdatedAt,
    required String remoteUpdatedAt,
    int localVersion = 1,
    int remoteVersion = 1,
    String localUpdatedBy = '',
    String remoteUpdatedBy = '',
  }) {
    final localDate = DateTime.tryParse(localUpdatedAt);
    final remoteDate = DateTime.tryParse(remoteUpdatedAt);
    if (localDate == null && remoteDate == null) {
      return localVersion == remoteVersion
          ? ConflictRecommendation.noConflict
          : ConflictRecommendation.manualReview;
    }
    if (localDate != null && remoteDate == null) {
      return ConflictRecommendation.localNewer;
    }
    if (localDate == null && remoteDate != null) {
      return ConflictRecommendation.remoteNewer;
    }
    if (localDate!.isAfter(remoteDate!)) {
      return ConflictRecommendation.localNewer;
    }
    if (remoteDate.isAfter(localDate)) {
      return ConflictRecommendation.remoteNewer;
    }
    if (localVersion != remoteVersion || localUpdatedBy != remoteUpdatedBy) {
      return ConflictRecommendation.manualReview;
    }
    return ConflictRecommendation.noConflict;
  }

  bool canRetryDirectly(PendingSyncItem item) => item.status != 'conflict';

  PendingSyncItem createResolutionOperation({
    required PendingSyncItem conflict,
    required Map<String, dynamic> payload,
    required int remoteVersion,
    required String newLocalOperationId,
    required String newIdempotencyKey,
    String createdAt = '',
  }) {
    if (conflict.status != 'conflict') {
      throw ArgumentError.value(conflict.status, 'conflict.status');
    }
    if (newLocalOperationId.isEmpty || newIdempotencyKey.isEmpty) {
      throw ArgumentError('Une nouvelle identité d’opération est requise.');
    }
    return PendingSyncItem(
      id: newLocalOperationId,
      localOperationId: newLocalOperationId,
      idempotencyKey: newIdempotencyKey,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      action: conflict.action,
      payload: payload,
      createdAt: createdAt,
      updatedAt: createdAt,
      baseVersion: remoteVersion,
      resolvedFromOperationId: conflict.serverOperationId.isNotEmpty
          ? conflict.serverOperationId
          : conflict.localOperationId,
    );
  }
}
