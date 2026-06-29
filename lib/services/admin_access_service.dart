import '../models/admin_access.dart';
import '../models/family_tree_data.dart';

enum AdminCodeRotationStatus { upToDate, dueSoon, late }

class AdminAccessService {
  const AdminAccessService();

  static const defaultAdminCode = 'AYIVONVI2026';

  bool validate(FamilyTreeData data, String code) {
    final normalized = normalizeCode(code);
    if (normalized == defaultAdminCode) return true;
    if (!data.adminAccess.enabled) return false;
    if (normalizeCode(data.adminAccess.currentAdminCode) == normalized) {
      return true;
    }
    return data.accessCodes.any(
      (item) =>
          item.enabled &&
          item.type == 'adminKpi' &&
          normalizeCode(item.code) == normalized,
    );
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
    if (!validate(data, oldCode)) {
      throw StateError('invalid_admin_code');
    }
    if (newCode.trim().length < 8) {
      throw StateError('admin_code_too_short');
    }
    if (oldCode.trim().toUpperCase() == newCode.trim().toUpperCase()) {
      throw StateError('admin_code_must_change');
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final nextDue = DateTime(
      now.year,
      now.month + data.adminAccess.rotationMonths,
      now.day,
      now.hour,
      now.minute,
      now.second,
    ).toIso8601String();

    final previousHistory = data.adminAccess.codeHistory.map((item) {
      if (item.code == data.adminAccess.currentAdminCode &&
          item.expiredAt.isEmpty) {
        return AdminCodeHistory(
          code: item.code,
          createdAt: item.createdAt,
          expiredAt: nowIso,
          changedByAdminId: item.changedByAdminId,
        );
      }
      return item;
    }).toList();

    final nextAccess = data.adminAccess.copyWith(
      currentAdminCode: newCode.trim(),
      lastChangedAt: nowIso,
      nextChangeDueAt: nextDue,
      codeHistory: [
        ...previousHistory,
        AdminCodeHistory(
          code: newCode.trim(),
          createdAt: nowIso,
          changedByAdminId: changedByAdminId,
        ),
      ],
    );
    return data.copyWith(adminAccess: nextAccess);
  }
}
