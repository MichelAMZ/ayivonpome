import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/activity_log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows only superAdmin to clear the activity log', () {
    const service = ActivityLogService();

    expect(service.canClearActivityLog('superAdmin'), isTrue);
    expect(service.canClearActivityLog('admin'), isFalse);
    expect(service.canClearActivityLog('editor'), isFalse);
    expect(service.canClearActivityLog('viewer'), isFalse);
  });

  test('clears only selected family entries older than the period', () {
    const service = ActivityLogService();
    final now = DateTime(2026, 7, 16);
    final data = FamilyTreeData.demo().copyWith(
      mainFamilyCode: 'ayivon',
      auditLog: [
        AuditLog(
          id: 'old-ayivon',
          date: now.subtract(const Duration(days: 100)).toIso8601String(),
          action: 'old',
          familyCode: 'ayivon',
        ),
        AuditLog(
          id: 'recent-ayivon',
          date: now.subtract(const Duration(days: 10)).toIso8601String(),
          action: 'recent',
          familyCode: 'ayivon',
        ),
        AuditLog(
          id: 'old-other',
          date: now.subtract(const Duration(days: 100)).toIso8601String(),
          action: 'old-other',
          familyCode: 'other',
        ),
      ],
    );

    final result = service.clearLocalEntries(
      data,
      period: ActivityLogClearPeriod.olderThan3Months,
      now: now,
    );

    expect(result.deletedCount, 1);
    expect(result.data.auditLog.map((item) => item.id), [
      'recent-ayivon',
      'old-other',
    ]);
  });
}
