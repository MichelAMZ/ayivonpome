import '../../../../../models/family_tree_data.dart';
import '../services/family_relationship_service.dart';

class LinkExistingFatherUseCase {
  const LinkExistingFatherUseCase({
    this.relationshipService = const FamilyRelationshipService(),
  });

  final FamilyRelationshipService relationshipService;

  FamilyTreeData call({
    required FamilyTreeData data,
    required String childId,
    required String fatherId,
  }) {
    return relationshipService.linkExistingFather(
      data: data,
      childId: childId,
      fatherId: fatherId,
    );
  }
}
