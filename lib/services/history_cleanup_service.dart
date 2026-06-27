import '../models/family_tree_data.dart';

class HistoryCleanupService {
  const HistoryCleanupService();

  static const retentionDays = 90;

  HistoryCleanupResult cleanOldNotificationHistory(
    FamilyTreeData data, {
    DateTime? now,
  }) {
    return deleteEntriesOlderThan90Days(data, now: now);
  }

  HistoryCleanupResult deleteEntriesOlderThan90Days(
    FamilyTreeData data, {
    DateTime? now,
  }) {
    final cleanedAt = now ?? DateTime.now();
    final threshold = cleanedAt.subtract(const Duration(days: retentionDays));
    final retained = data.infoNewsSendLogs.where((entry) {
      final createdAt = DateTime.tryParse(entry.createdAt);
      final fallbackDate = DateTime.tryParse(entry.date);
      final date = createdAt ?? fallbackDate;
      if (date == null) return true;
      return !date.isBefore(threshold);
    }).toList();
    final retainedAnnouncements = data.familyAnnouncementHistory.where((entry) {
      final createdAt = DateTime.tryParse(entry.createdAt);
      final fallbackDate = DateTime.tryParse(entry.date);
      final date = createdAt ?? fallbackDate;
      if (date == null) return true;
      return !date.isBefore(threshold);
    }).toList();
    return HistoryCleanupResult(
      data: data.copyWith(
        infoNewsSendLogs: retained,
        familyAnnouncementHistory: retainedAnnouncements,
        infoNewsSendHistoryLastCleanedAt: cleanedAt.toIso8601String(),
      ),
      deletedCount:
          data.infoNewsSendLogs.length -
          retained.length +
          data.familyAnnouncementHistory.length -
          retainedAnnouncements.length,
      retainedCount: retained.length,
      cleanedAt: cleanedAt,
    );
  }
}

class HistoryCleanupResult {
  const HistoryCleanupResult({
    required this.data,
    required this.deletedCount,
    required this.retainedCount,
    required this.cleanedAt,
  });

  final FamilyTreeData data;
  final int deletedCount;
  final int retainedCount;
  final DateTime cleanedAt;

  bool get hasChanges => deletedCount > 0;
}
