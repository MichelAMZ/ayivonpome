import 'dart:math' as math;

import '../models/family_tree_data.dart';
import '../models/person.dart';

class CoupleGroup {
  const CoupleGroup({
    this.husbandId,
    this.wifeId,
    this.spouseIds = const [],
    this.childrenIds = const [],
    required this.generation,
  });

  final String? husbandId;
  final String? wifeId;
  final List<String> spouseIds;
  final List<String> childrenIds;
  final int generation;
}

class GenealogyLayoutService {
  const GenealogyLayoutService();

  Map<String, int> computeGenerations(FamilyTreeData data) {
    final peopleById = {for (final person in data.people) person.id: person};
    final union = _UnionFind(peopleById.keys);

    for (final person in data.people) {
      for (final spouseId in _spouseIds(person, data)) {
        if (peopleById.containsKey(spouseId) && spouseId != person.id) {
          union.union(person.id, spouseId);
        }
      }
    }

    final parentGroupsByChildGroup = <String, Set<String>>{};
    for (final person in data.people) {
      final childGroup = union.find(person.id);
      for (final parentId in _parentIds(person)) {
        if (!peopleById.containsKey(parentId) || parentId == person.id) {
          continue;
        }
        final parentGroup = union.find(parentId);
        if (parentGroup == childGroup) continue;
        parentGroupsByChildGroup
            .putIfAbsent(childGroup, () => <String>{})
            .add(parentGroup);
      }
    }

    final memo = <String, int>{};
    final visiting = <String>{};
    int generationOfGroup(String groupId) {
      final cached = memo[groupId];
      if (cached != null) return cached;
      if (!visiting.add(groupId)) {
        return memo[groupId] = 0;
      }
      final parents = parentGroupsByChildGroup[groupId] ?? const <String>{};
      final value = parents.isEmpty
          ? 0
          : parents
                .map((parentGroup) => generationOfGroup(parentGroup) + 1)
                .fold<int>(0, math.max);
      visiting.remove(groupId);
      return memo[groupId] = value;
    }

    return {
      for (final person in data.people)
        person.id: generationOfGroup(union.find(person.id)),
    };
  }

  List<CoupleGroup> computeCoupleGroups(FamilyTreeData data) {
    final generations = computeGenerations(data);
    final peopleById = {for (final person in data.people) person.id: person};
    final seen = <String>{};
    final groups = <CoupleGroup>[];

    for (final person in data.people) {
      if (seen.contains(person.id)) continue;
      final spouses = _spouseIds(
        person,
        data,
      ).where(peopleById.containsKey).where((id) => id != person.id).toList();
      final memberIds = <String>{person.id, ...spouses};
      seen.addAll(memberIds);
      final members = memberIds.map((id) => peopleById[id]).whereType<Person>();
      final children = <String>{
        for (final member in members) ..._childIds(member, data),
      }.toList();
      String? husband;
      String? wife;
      for (final member in members) {
        if (husband == null && _isMale(member)) husband = member.id;
        if (wife == null && _isFemale(member)) wife = member.id;
      }
      groups.add(
        CoupleGroup(
          husbandId: husband,
          wifeId: wife,
          spouseIds: memberIds.toList(),
          childrenIds: children,
          generation: generations[person.id] ?? 0,
        ),
      );
    }
    return groups;
  }

  Map<String, Object> computeNodePositions(FamilyTreeData data) {
    return {'generations': computeGenerations(data)};
  }

  List<String> validateRelationshipGraph(FamilyTreeData data) {
    final errors = <String>[];
    final peopleById = {for (final person in data.people) person.id: person};
    final descendantMemo = <String, Set<String>>{};

    Set<String> descendantsOf(String personId, Set<String> visiting) {
      final cached = descendantMemo[personId];
      if (cached != null) return cached;
      if (!visiting.add(personId)) return {};
      final person = peopleById[personId];
      if (person == null) return {};
      final descendants = <String>{};
      for (final childId in _childIds(person, data)) {
        if (!peopleById.containsKey(childId)) continue;
        descendants.add(childId);
        descendants.addAll(descendantsOf(childId, {...visiting}));
      }
      descendantMemo[personId] = descendants;
      return descendants;
    }

    for (final person in data.people) {
      if (person.fatherId == person.id) {
        errors.add('${person.id}: self_father');
      }
      if (person.motherId == person.id) {
        errors.add('${person.id}: self_mother');
      }
      if (person.childrenIds.contains(person.id) ||
          person.children.contains(person.id)) {
        errors.add('${person.id}: self_child');
      }
      if (_spouseIds(person, data).contains(person.id)) {
        errors.add('${person.id}: self_spouse');
      }
      final descendants = descendantsOf(person.id, <String>{});
      for (final spouseId in _spouseIds(person, data)) {
        if (descendants.contains(spouseId)) {
          errors.add('${person.id}: spouse_as_descendant:$spouseId');
        }
      }
      for (final parentId in _parentIds(person)) {
        if (descendants.contains(parentId)) {
          errors.add('${person.id}: ancestor_cycle:$parentId');
        }
      }
    }
    return errors;
  }

  static List<String> _parentIds(Person person) {
    return {
      if (person.fatherId.isNotEmpty) person.fatherId,
      if (person.motherId.isNotEmpty) person.motherId,
      ...person.parents,
    }.toList();
  }

  static List<String> _spouseIds(Person person, FamilyTreeData data) {
    final ids = <String>[...person.spouseIds, ...person.spouses];
    for (final relation in data.marriageRelations) {
      if (relation.personId == person.id) ids.add(relation.spouseId);
      if (relation.spouseId == person.id) ids.add(relation.personId);
    }
    return ids.toSet().toList();
  }

  static List<String> _childIds(Person person, FamilyTreeData data) {
    final ids = <String>[...person.childrenIds, ...person.children];
    for (final candidate in data.people) {
      if (candidate.fatherId == person.id ||
          candidate.motherId == person.id ||
          candidate.parents.contains(person.id)) {
        ids.add(candidate.id);
      }
    }
    return ids.toSet().toList();
  }

  static bool _isMale(Person person) {
    final gender = person.gender.toLowerCase().trim();
    return gender == 'male' || gender == 'm' || gender == 'homme';
  }

  static bool _isFemale(Person person) {
    final gender = person.gender.toLowerCase().trim();
    return gender == 'female' || gender == 'f' || gender == 'femme';
  }
}

class _UnionFind {
  _UnionFind(Iterable<String> ids) : _parent = {for (final id in ids) id: id};

  final Map<String, String> _parent;

  String find(String id) {
    final parent = _parent[id] ?? id;
    if (parent == id) return id;
    final root = find(parent);
    _parent[id] = root;
    return root;
  }

  void union(String first, String second) {
    final firstRoot = find(first);
    final secondRoot = find(second);
    if (firstRoot != secondRoot) _parent[secondRoot] = firstRoot;
  }
}
