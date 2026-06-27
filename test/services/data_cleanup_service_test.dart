import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_notification.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/data_cleanup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleans only old notifications and old KPI activity logs', () {
    final now = DateTime(2026, 6, 27, 12);
    final oldNotification = now.subtract(const Duration(days: 8));
    final recentNotification = now.subtract(const Duration(days: 7));
    final oldLog = now.subtract(const Duration(days: 91));
    final recentLog = now.subtract(const Duration(days: 90));
    final data = FamilyTreeData(
      people: const [Person(id: 'p1', firstName: 'Kossi')],
      notifications: [
        FamilyNotification(
          id: 'old_notification',
          createdAt: oldNotification.toIso8601String(),
        ),
        FamilyNotification(
          id: 'recent_notification',
          createdAt: recentNotification.toIso8601String(),
        ),
      ],
      auditLog: [
        AuditLog(
          id: 'old_log',
          date: oldLog.toIso8601String(),
          action: 'create_person',
        ),
        AuditLog(
          id: 'recent_log',
          date: recentLog.toIso8601String(),
          action: 'edit_person',
        ),
      ],
    );

    final result = const DataCleanupService().runAutomaticCleanup(
      data,
      now: now,
    );

    expect(result.deletedCount, 2);
    expect(result.data.people.single.id, 'p1');
    expect(result.data.notifications.single.id, 'recent_notification');
    expect(result.data.auditLog.single.id, 'recent_log');
    expect(result.data.dataCleanupLastDeletedCount, 2);
  });
}
