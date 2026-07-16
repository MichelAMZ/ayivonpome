import '../models/audit_log.dart';
import '../models/family_tree_data.dart';

enum ActivityLogClearPeriod {
  olderThan7Days,
  olderThan30Days,
  olderThan3Months,
  all,
}

class ActivityLogClearResult {
  const ActivityLogClearResult({
    required this.data,
    required this.deletedCount,
    required this.period,
    required this.olderThan,
  });

  final FamilyTreeData data;
  final int deletedCount;
  final ActivityLogClearPeriod period;
  final DateTime? olderThan;
}

class ActivityLogService {
  const ActivityLogService();

  bool canClearActivityLog(String role) => role == 'superAdmin';

  int countEntries(FamilyTreeData data) => data.auditLog.length;

  DateTime? thresholdFor(ActivityLogClearPeriod period, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return switch (period) {
      ActivityLogClearPeriod.olderThan7Days => current.subtract(
        const Duration(days: 7),
      ),
      ActivityLogClearPeriod.olderThan30Days => current.subtract(
        const Duration(days: 30),
      ),
      ActivityLogClearPeriod.olderThan3Months => current.subtract(
        const Duration(days: 90),
      ),
      ActivityLogClearPeriod.all => null,
    };
  }

  String labelFor(ActivityLogClearPeriod period) {
    return switch (period) {
      ActivityLogClearPeriod.olderThan7Days => 'plus_de_7_jours',
      ActivityLogClearPeriod.olderThan30Days => 'plus_de_30_jours',
      ActivityLogClearPeriod.olderThan3Months => 'plus_de_3_mois',
      ActivityLogClearPeriod.all => 'tout_le_journal',
    };
  }

  ActivityLogClearResult clearLocalEntries(
    FamilyTreeData data, {
    required ActivityLogClearPeriod period,
    DateTime? now,
  }) {
    final olderThan = thresholdFor(period, now: now);
    final kept = data.auditLog.where((item) {
      return !_matches(item, data.mainFamilyCode, olderThan);
    }).toList();
    return ActivityLogClearResult(
      data: data.copyWith(auditLog: kept),
      deletedCount: data.auditLog.length - kept.length,
      period: period,
      olderThan: olderThan,
    );
  }

  bool _matches(AuditLog item, String familyId, DateTime? olderThan) {
    if (familyId.isNotEmpty &&
        item.familyCode.isNotEmpty &&
        item.familyCode != familyId) {
      return false;
    }
    if (olderThan == null) return true;
    final createdAt = DateTime.tryParse(item.date);
    if (createdAt == null) return false;
    return createdAt.isBefore(olderThan);
  }
}
