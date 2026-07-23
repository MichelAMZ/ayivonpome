import 'package:shared_preferences/shared_preferences.dart';

import '../models/family_tree_data.dart';

class AuthSession {
  const AuthSession({required this.familyCode, required this.role});

  final String familyCode;
  final String role;

  bool get isSuperAdmin => role == 'superAdmin';
  bool get isAdmin => role == 'admin' || role == 'superAdmin';
  bool get isOwner => role == 'owner' || isSuperAdmin;
  bool get canManageBranding => isSuperAdmin || role == 'admin';
}

class AuthCodeService {
  static const _lastCodeKey = 'last_family_code';

  AuthSession? verifyCode(FamilyTreeData data, String code) {
    // Les identifiants familiaux locaux ne constituent jamais une preuve
    // d'authentification ou d'autorisation.
    return null;
  }

  Future<String?> readLastCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCodeKey);
    return null;
  }

  Future<void> saveLastCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCodeKey);
  }
}
