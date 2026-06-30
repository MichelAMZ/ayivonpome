import '../models/family_tree_data.dart';

class SuperAdminRecoveryService {
  const SuperAdminRecoveryService();

  bool validate(FamilyTreeData data, String code) {
    final recovery = data.superAdminRecovery;
    if (!recovery.enabled) return false;
    return code.trim() == recovery.recoveryCode.trim();
  }
}
