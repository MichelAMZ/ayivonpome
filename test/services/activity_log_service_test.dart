import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/activity_log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows active admin roles to clear the activity log', () {
    const service = ActivityLogService();

    expect(service.canClearActivityLog('superAdmin'), isTrue);
    expect(service.canClearActivityLog('admin'), isTrue);
    expect(service.canClearActivityLog('editor'), isFalse);
    expect(service.canClearActivityLog('viewer'), isFalse);
  });

  test('translates technical codes and computes real KPIs', () {
    const service = ActivityLogService();
    const logs = [
      AuditLog(
        id: '1',
        date: '2026-07-20T12:00:00Z',
        action: 'sync_remote_success',
      ),
      AuditLog(
        id: '2',
        date: '2026-07-20T11:00:00Z',
        action: 'sync_queue_item_failed',
      ),
      AuditLog(id: '3', date: '2026-07-20T10:00:00Z', action: 'delete_person'),
    ];

    expect(
      service.labelForAction('sync_remote_success'),
      'Synchronisation réussie',
    );
    expect(service.labelForAction('unknown_event'), 'Unknown event');
    final kpis = service.computeKpis(logs);
    expect(kpis.total, 3);
    expect(kpis.successfulSyncs, 1);
    expect(kpis.failures, 1);
    expect(kpis.deletions, 1);
  });

  test('searches, filters and sorts activities by descending date', () {
    const service = ActivityLogService();
    const logs = [
      AuditLog(
        id: 'old',
        date: '2026-07-19T10:00:00Z',
        action: 'update_person',
        personId: 'p001',
        actorRole: 'editor',
      ),
      AuditLog(
        id: 'new',
        date: '2026-07-20T10:00:00Z',
        action: 'authorization_failed',
        description: 'Accès refusé',
        actorRole: 'admin',
      ),
    ];

    expect(service.filterAndSort(logs).map((log) => log.id), ['new', 'old']);
    expect(service.filterAndSort(logs, query: 'p001').single.id, 'old');
    expect(service.filterAndSort(logs, status: 'failure').single.id, 'new');
    expect(service.filterAndSort(logs, user: 'editor').single.id, 'old');
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
