class ActivityLogDeletionResult {
  const ActivityLogDeletionResult({
    required this.requestedCount,
    required this.deletedCount,
    required this.failedIds,
    this.errorCode,
  });

  final int requestedCount;
  final int deletedCount;
  final List<String> failedIds;
  final String? errorCode;

  int get failedCount => failedIds.length;
  bool get isComplete => failedIds.isEmpty && deletedCount == requestedCount;
}
