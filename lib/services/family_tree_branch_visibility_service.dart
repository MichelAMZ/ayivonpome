import 'package:shared_preferences/shared_preferences.dart';

import '../models/family_tree_data.dart';
import '../models/person.dart';

class FamilyTreeBranchVisibilityService {
  const FamilyTreeBranchVisibilityService();

  static const storageKeyPrefix = 'familyTree.collapsedBranches.';

  Set<String> collectDescendantIds(String memberId, List<Person> people) {
    final childrenByParent = <String, Set<String>>{};
    for (final person in people) {
      for (final parentId in _parentIds(person)) {
        if (parentId.isEmpty || parentId == person.id) continue;
        childrenByParent.putIfAbsent(parentId, () => <String>{}).add(person.id);
      }
      for (final childId in {...person.childrenIds, ...person.children}) {
        if (childId.isEmpty || childId == person.id) continue;
        childrenByParent.putIfAbsent(person.id, () => <String>{}).add(childId);
      }
    }

    final descendants = <String>{};
    final visited = <String>{memberId};
    final pending = <String>[memberId];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final childId in childrenByParent[current] ?? const <String>{}) {
        if (!visited.add(childId)) continue;
        descendants.add(childId);
        pending.add(childId);
      }
    }
    return descendants;
  }

  Set<String> hiddenMemberIds(
    FamilyTreeData data,
    Set<String> collapsedRootIds,
  ) {
    final hidden = <String>{};
    for (final rootId in collapsedRootIds) {
      hidden.addAll(collectDescendantIds(rootId, data.people));
    }
    _includeExclusiveSpouses(data, hidden, collapsedRootIds);
    return hidden;
  }

  FamilyTreeData visibleData(
    FamilyTreeData data,
    Set<String> collapsedRootIds,
  ) {
    final hidden = hiddenMemberIds(data, collapsedRootIds);
    if (hidden.isEmpty) return data;
    final visiblePeople = data.people
        .where((person) => !hidden.contains(person.id))
        .toList(growable: false);
    final visibleIds = visiblePeople.map((person) => person.id).toSet();
    return data.copyWith(
      people: visiblePeople,
      marriageRelations: data.marriageRelations
          .where(
            (relation) =>
                visibleIds.contains(relation.personId) &&
                visibleIds.contains(relation.spouseId),
          )
          .toList(growable: false),
      familyLinks: data.familyLinks
          .where(
            (link) =>
                visibleIds.contains(link.fromPersonId) &&
                visibleIds.contains(link.toPersonId),
          )
          .toList(growable: false),
    );
  }

  Set<String> collapsedRootsHiding(
    String memberId,
    FamilyTreeData data,
    Set<String> collapsedRootIds,
  ) {
    return collapsedRootIds
        .where(
          (rootId) =>
              collectDescendantIds(rootId, data.people).contains(memberId),
        )
        .toSet();
  }

  Future<Set<String>> load(String familyId) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList('$storageKeyPrefix$familyId') ??
            const <String>[])
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();
  }

  Future<void> save(String familyId, Set<String> collapsedRootIds) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = collapsedRootIds.toList()..sort();
    await preferences.setStringList('$storageKeyPrefix$familyId', ids);
  }

  Set<String> _parentIds(Person person) => <String>{
    person.fatherId,
    person.motherId,
    ...person.parents,
  };

  void _includeExclusiveSpouses(
    FamilyTreeData data,
    Set<String> hidden,
    Set<String> collapsedRoots,
  ) {
    final peopleById = {for (final person in data.people) person.id: person};
    final spousesByPerson = <String, Set<String>>{};
    for (final person in data.people) {
      spousesByPerson.putIfAbsent(person.id, () => <String>{}).addAll({
        ...person.spouseIds,
        ...person.spouses,
      });
    }
    for (final relation in data.marriageRelations) {
      spousesByPerson
          .putIfAbsent(relation.personId, () => <String>{})
          .add(relation.spouseId);
      spousesByPerson
          .putIfAbsent(relation.spouseId, () => <String>{})
          .add(relation.personId);
    }

    var changed = true;
    while (changed) {
      changed = false;
      final candidates = <String>{};
      for (final hiddenId in hidden) {
        candidates.addAll(spousesByPerson[hiddenId] ?? const <String>{});
      }
      for (final candidateId in candidates) {
        if (hidden.contains(candidateId) ||
            collapsedRoots.contains(candidateId) ||
            !peopleById.containsKey(candidateId)) {
          continue;
        }
        final spouses = spousesByPerson[candidateId] ?? const <String>{};
        final hasVisibleUnion = spouses.any(
          (spouseId) => !hidden.contains(spouseId),
        );
        if (hasVisibleUnion) continue;
        hidden.add(candidateId);
        changed = true;
      }
    }
  }
}
