import '../models/admin_user.dart';
import '../models/family_tree_data.dart';

class AdminService {
  List<AdminUser> activeAdmins(FamilyTreeData data) =>
      data.admins.where((admin) => admin.active).toList();

  bool canManageAdmins(String role) => role == 'superAdmin';
  bool canViewKpi(String role) => role == 'superAdmin' || role == 'admin';
}
