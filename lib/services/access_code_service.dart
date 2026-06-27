import 'dart:math';

import '../models/access_code.dart';
import '../models/family_tree_data.dart';

class AccessCodeService {
  const AccessCodeService();

  List<AccessCode> visibleCodes(FamilyTreeData data, String role) {
    if (role == 'superAdmin') return data.accessCodes;
    return data.accessCodes
        .where((code) => code.role != 'superAdmin' && code.type != 'adminKpi')
        .toList();
  }

  AccessCode upsert(
    FamilyTreeData data,
    AccessCode code, {
    required String actorRole,
    required bool isCreate,
  }) {
    final normalized = code.code.trim().toUpperCase();
    if (normalized.length < 6) throw StateError('code_too_short');
    final duplicate = data.accessCodes.any(
      (item) =>
          item.id != code.id && item.code.trim().toUpperCase() == normalized,
    );
    if (duplicate) throw StateError('code_already_exists');
    if (code.role == 'superAdmin' && actorRole != 'superAdmin') {
      throw StateError('forbidden');
    }
    if (code.type == 'adminKpi' && actorRole != 'superAdmin') {
      throw StateError('forbidden');
    }
    final now = DateTime.now().toIso8601String();
    return code.copyWith(
      id: code.id.isEmpty
          ? 'code${DateTime.now().microsecondsSinceEpoch}'
          : code.id,
      code: code.code.trim(),
      createdAt: code.createdAt.isEmpty ? now : code.createdAt,
      updatedAt: isCreate ? code.updatedAt : now,
    );
  }

  AccessCode toggle(AccessCode code, {required bool enabled}) {
    return code.copyWith(
      enabled: enabled,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  bool canDelete(AccessCode code, String actorRole) {
    if (actorRole == 'superAdmin') return true;
    return !code.isImportant && code.createdByAdminId.isNotEmpty;
  }

  bool canRegenerate(
    AccessCode code, {
    required String actorRole,
    required String adminId,
  }) {
    if (actorRole == 'superAdmin') return true;
    if (actorRole != 'admin') return false;
    if (code.role == 'superAdmin') return false;
    if (code.type == 'adminKpi' && code.createdByAdminId != adminId) {
      return false;
    }
    return code.createdByAdminId == adminId || code.familyCode == adminId;
  }

  String generateSecureCode(String type) {
    final prefix = switch (type) {
      'adminKpi' => 'ADMIN',
      'modification' => 'EDIT',
      'temporary' => 'TEMP',
      'linkedFamily' || 'familyAccess' => 'FAMILY',
      _ => 'FAMILY',
    };
    return '$prefix-${_randomChunk(4)}-${_randomChunk(4)}';
  }

  String generateUniqueSecureCode(FamilyTreeData data, String type) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final code = generateSecureCode(type);
      if (!_codeExists(data, code)) return code;
    }
    throw StateError('code_generation_failed');
  }

  String generateCode({int length = 10}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  String _randomChunk(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  bool _codeExists(FamilyTreeData data, String code) {
    final normalized = code.trim().toUpperCase();
    return data.accessCodes.any(
          (item) => item.code.trim().toUpperCase() == normalized,
        ) ||
        data.familyCodes.any(
          (item) => item.code.trim().toUpperCase() == normalized,
        ) ||
        data.modificationCodes.any(
          (item) => item.code.trim().toUpperCase() == normalized,
        ) ||
        data.familyLinks.any(
          (item) => item.linkedFamilyCode.trim().toUpperCase() == normalized,
        );
  }

  static final _random = Random.secure();
}
