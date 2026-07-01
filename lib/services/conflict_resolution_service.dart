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
}
