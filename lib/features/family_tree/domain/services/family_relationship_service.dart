import '../../../../../models/family_tree_data.dart';
import '../../../../../models/person.dart';
import '../enums/parent_role.dart';
import '../errors/family_relationship_error.dart';

class FamilyRelationshipService {
  const FamilyRelationshipService();

  FamilyTreeData linkExistingParent({
    required FamilyTreeData data,
    required String childId,
    required String parentId,
    required ParentRole role,
  }) {
    if (childId == parentId) throw const InvalidFamilyRelationship();
    final peopleById = {for (final person in data.people) person.id: person};
    final child = peopleById[childId];
    final parent = peopleById[parentId];
    if (child == null || parent == null) throw const MemberNotFound();
    if (role == ParentRole.unspecified) {
      throw const InvalidFamilyRelationship();
    }
    if (_isDescendant(data, child.id, parent.id)) {
      throw const RelationshipCycleDetected();
    }

    final currentParentId = role == ParentRole.father
        ? child.fatherId
        : child.motherId;
    if (currentParentId.isNotEmpty && currentParentId != parent.id) {
      throw const ParentAlreadyAssigned();
    }

    final nextChild = role == ParentRole.father
        ? child.copyWith(
            fatherId: parent.id,
            parents: {...child.parents, parent.id}.toList(),
          )
        : child.copyWith(
            motherId: parent.id,
            parents: {...child.parents, parent.id}.toList(),
          );
    final nextParent = parent.copyWith(
      childrenIds: {...parent.childrenIds, child.id}.toList(),
      children: {...parent.children, child.id}.toList(),
    );

    return _replacePeople(data, [nextChild, nextParent]);
  }

  FamilyTreeData linkExistingFather({
    required FamilyTreeData data,
    required String childId,
    required String fatherId,
  }) {
    return linkExistingParent(
      data: data,
      childId: childId,
      parentId: fatherId,
      role: ParentRole.father,
    );
  }

  FamilyTreeData _replacePeople(FamilyTreeData data, List<Person> changed) {
    final byId = {for (final person in data.people) person.id: person};
    for (final person in changed) {
      byId[person.id] = person;
    }
    return data.copyWith(people: byId.values.toList());
  }

  bool _isDescendant(
    FamilyTreeData data,
    String ancestorId,
    String descendantId, [
    Set<String>? visited,
  ]) {
    if (ancestorId == descendantId) return true;
    final seen = visited ?? <String>{};
    if (!seen.add(ancestorId)) return false;
    final ancestor = data.people
        .where((person) => person.id == ancestorId)
        .firstOrNull;
    if (ancestor == null) return false;
    final children = data.people.where(
      (person) =>
          ancestor.childrenIds.contains(person.id) ||
          ancestor.children.contains(person.id) ||
          person.fatherId == ancestor.id ||
          person.motherId == ancestor.id ||
          person.parents.contains(ancestor.id),
    );
    for (final child in children) {
      if (child.id == descendantId ||
          _isDescendant(data, child.id, descendantId, seen)) {
        return true;
      }
    }
    return false;
  }
}
