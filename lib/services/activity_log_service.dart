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

  bool canClearActivityLog(String role) =>
      role == 'admin' || role == 'superAdmin';

  String labelForAction(String action) => switch (action) {
    'sync_remote_success' => 'Synchronisation réussie',
    'sync_queue_item_failed' => 'Échec de synchronisation',
    'delete_person' || 'delete_person_confirmed' => 'Membre supprimé',
    'create_person' => 'Membre ajouté',
    'update_person' => 'Membre modifié',
    'login_success' => 'Connexion réussie',
    'authorization_failed' => 'Autorisation refusée',
    _ => _humanize(action),
  };

  String statusFor(AuditLog log) {
    final value = '${log.action} ${log.description}'.toLowerCase();
    if (value.contains('failed') ||
        value.contains('error') ||
        value.contains('refus')) {
      return 'failure';
    }
    if (value.contains('pending') || value.contains('queue')) return 'pending';
    if (value.contains('cancel')) return 'cancelled';
    if (value.contains('success') ||
        value.contains('confirm') ||
        value.contains('create') ||
        value.contains('update') ||
        value.contains('delete')) {
      return 'success';
    }
    return 'info';
  }

  List<AuditLog> filterAndSort(
    Iterable<AuditLog> entries, {
    String query = '',
    String type = 'all',
    String status = 'all',
    String user = 'all',
    DateTime? from,
    DateTime? to,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = entries
        .where((log) {
          final date = DateTime.tryParse(log.date);
          if (type != 'all' && log.action != type) return false;
          if (status != 'all' && statusFor(log) != status) return false;
          if (user != 'all' && log.actorRole != user && log.adminId != user) {
            return false;
          }
          if (from != null && (date == null || date.isBefore(from))) {
            return false;
          }
          if (to != null && (date == null || date.isAfter(to))) return false;
          if (normalizedQuery.isEmpty) return true;
          return [
            labelForAction(log.action),
            log.action,
            log.personId,
            log.familyCode,
            log.actorRole,
            log.adminId,
            log.description,
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
        })
        .toList(growable: false);
    filtered.sort((a, b) {
      final left =
          DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right =
          DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return filtered;
  }

  ActivityLogKpis computeKpis(Iterable<AuditLog> entries) {
    final logs = entries.toList(growable: false);
    return ActivityLogKpis(
      total: logs.length,
      successfulSyncs: logs
          .where((log) => log.action == 'sync_remote_success')
          .length,
      failures: logs.where((log) => statusFor(log) == 'failure').length,
      deletions: logs
          .where((log) => log.action.toLowerCase().contains('delete'))
          .length,
    );
  }

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

  String _humanize(String action) {
    final words = action
        .trim()
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .join(' ');
    if (words.isEmpty) return 'Activité enregistrée';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

class ActivityLogKpis {
  const ActivityLogKpis({
    required this.total,
    required this.successfulSyncs,
    required this.failures,
    required this.deletions,
  });

  final int total;
  final int successfulSyncs;
  final int failures;
  final int deletions;
}
