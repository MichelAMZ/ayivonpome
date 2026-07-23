import '../models/family_tree_data.dart';

enum AdminCodeRotationStatus { upToDate, dueSoon, late }

class AdminAccessService {
  const AdminAccessService();

  bool validate(FamilyTreeData data, String code) {
    return false;
  }

  static String normalizeCode(String code) =>
      code.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  AdminCodeRotationStatus rotationStatus(FamilyTreeData data) {
    final dueAt = DateTime.tryParse(data.adminAccess.nextChangeDueAt);
    if (dueAt == null) return AdminCodeRotationStatus.upToDate;
    final now = DateTime.now();
    if (!dueAt.isAfter(now)) return AdminCodeRotationStatus.late;
    if (dueAt.difference(now).inDays <= 21) {
      return AdminCodeRotationStatus.dueSoon;
    }
    return AdminCodeRotationStatus.upToDate;
  }

  FamilyTreeData changeCode({
    required FamilyTreeData data,
    required String oldCode,
    required String newCode,
    required String changedByAdminId,
  }) {
    throw StateError('local_admin_code_disabled');
  }
}
