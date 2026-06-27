import '../models/family_tree_data.dart';

class DataCleanupService {
  const DataCleanupService();

  static const notificationRetentionDays = 7;
  static const kpiActivityRetentionDays = 90;

  FamilyTreeData cleanOldNotifications(FamilyTreeData data, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final threshold = current.subtract(
      const Duration(days: notificationRetentionDays),
    );
    return data.copyWith(
      notifications: data.notifications.where((item) {
        final createdAt = DateTime.tryParse(item.createdAt);
        if (createdAt == null) return true;
        return !createdAt.isBefore(threshold);
      }).toList(),
    );
  }

  FamilyTreeData cleanOldKpiActivityLogs(FamilyTreeData data, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final threshold = current.subtract(
      const Duration(days: kpiActivityRetentionDays),
    );
    return data.copyWith(
      auditLog: data.auditLog.where((item) {
        final createdAt = DateTime.tryParse(item.date);
        if (createdAt == null) return true;
        return !createdAt.isBefore(threshold);
      }).toList(),
    );
  }

  DataCleanupResult runAutomaticCleanup(FamilyTreeData data, {DateTime? now}) {
    final current = now ?? DateTime.now();
    var next = data;
    if (next.autoCleanupNotifications) {
      next = cleanOldNotifications(next, now: current);
    }
    if (next.autoCleanupKpiActivityLogs) {
      next = cleanOldKpiActivityLogs(next, now: current);
    }
    final deletedCount =
        data.notifications.length -
        next.notifications.length +
        data.auditLog.length -
        next.auditLog.length;
    return DataCleanupResult(
      data: next.copyWith(
        dataCleanupLastCleanedAt: current.toIso8601String(),
        dataCleanupLastDeletedCount: deletedCount,
      ),
      deletedCount: deletedCount,
      cleanedAt: current,
    );
  }
}

class DataCleanupResult {
  const DataCleanupResult({
    required this.data,
    required this.deletedCount,
    required this.cleanedAt,
  });

  final FamilyTreeData data;
  final int deletedCount;
  final DateTime cleanedAt;
}
