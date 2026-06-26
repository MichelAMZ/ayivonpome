import '../models/admin_kpi.dart';
import '../models/family_tree_data.dart';

class KpiService {
  AdminKpi compute(FamilyTreeData data) {
    final now = DateTime.now();
    final monthPrefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final added = data.auditLog
        .where((log) =>
            log.action == 'create_person' && log.date.startsWith(monthPrefix))
        .length;
    final modified = data.auditLog
        .where((log) =>
            log.action == 'edit_person' && log.date.startsWith(monthPrefix))
        .length;
    return AdminKpi(
      totalPeople: data.people.length,
      peopleAddedThisMonth: added,
      peopleModifiedThisMonth: modified,
      linkedFamilies: data.familyCodes.length,
      pendingFamilyLinks:
          data.familyLinks.where((link) => link.status == 'pending').length,
      activeCodes: data.modificationCodes.where((code) => code.isValid).length,
      expiredCodes: data.modificationCodes.where((code) => code.isExpired).length,
      adminActions:
          data.auditLog.where((log) => log.action.startsWith('admin_')).length,
      adminContactRequests: data.auditLog
          .where((log) => log.action == 'admin_contact_requested')
          .length,
    );
  }
}
