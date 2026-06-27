import '../models/family_council_member.dart';
import '../models/family_tree_data.dart';

class FamilyCouncilService {
  const FamilyCouncilService();

  List<FamilyCouncilMember> visibleMembers(
    FamilyTreeData data, {
    required bool publicLimited,
    required bool canManage,
  }) {
    final members =
        data.familyCouncil.members
            .where((member) => member.active || canManage)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return members;
  }

  bool canManage(String role) => role == 'superAdmin' || role == 'admin';

  bool canShowContact(
    FamilyCouncilMember member, {
    required bool publicLimited,
  }) {
    return !publicLimited && member.allowContact;
  }
}
