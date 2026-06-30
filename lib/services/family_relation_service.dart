import '../models/audit_log.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import 'genealogy_layout_service.dart';

class FamilyRelationService {
  const FamilyRelationService();

  FamilyTreeData addFather(
    FamilyTreeData data,
    Person child, {
    String actorRole = '',
  }) {
    final father = Person(
      id: _id('p'),
      firstName: 'Nouveau',
      lastName: 'père',
      gender: 'male',
      childrenIds: [child.id],
      children: [child.id],
      familyCode: child.familyCode,
    );
    final updatedChild = child.copyWith(
      fatherId: father.id,
      parents: {...child.parents, father.id}.toList(),
    );
    _assertCanBeParent(data, father.id, child.id);
    return _withPeople(
      data,
      [father, updatedChild],
      'add_father',
      actorRole,
      child.id,
    );
  }

  FamilyTreeData addMother(
    FamilyTreeData data,
    Person child, {
    String actorRole = '',
  }) {
    final mother = Person(
      id: _id('p'),
      firstName: 'Nouvelle',
      lastName: 'mère',
      gender: 'female',
      childrenIds: [child.id],
      children: [child.id],
      familyCode: child.familyCode,
    );
    final updatedChild = child.copyWith(
      motherId: mother.id,
      parents: {...child.parents, mother.id}.toList(),
    );
    _assertCanBeParent(data, mother.id, child.id);
    return _withPeople(
      data,
      [mother, updatedChild],
      'add_mother',
      actorRole,
      child.id,
    );
  }

  FamilyTreeData addParents(
    FamilyTreeData data,
    Person child, {
    String actorRole = '',
  }) {
    final withFather = addFather(data, child, actorRole: actorRole);
    final updatedChild = _byId(withFather, child.id) ?? child;
    return addMother(withFather, updatedChild, actorRole: actorRole);
  }

  FamilyTreeData addChild(
    FamilyTreeData data,
    Person parent, {
    String actorRole = '',
  }) {
    final child = Person(
      id: _id('p'),
      firstName: 'Nouvel',
      lastName: 'enfant',
      gender: '',
      familyCode: parent.familyCode,
      fatherId: _isMale(parent) ? parent.id : '',
      motherId: _isFemale(parent) ? parent.id : '',
      parents: [parent.id],
    );
    final updatedParent = parent.copyWith(
      childrenIds: {...parent.childrenIds, child.id}.toList(),
      children: {...parent.children, child.id}.toList(),
    );
    _assertCanBeParent(data, parent.id, child.id);
    return _withPeople(
      data,
      [child, updatedParent],
      'add_child',
      actorRole,
      parent.id,
    );
  }

  FamilyTreeData addSibling(
    FamilyTreeData data,
    Person person, {
    required String gender,
    String actorRole = '',
  }) {
    final sibling = Person(
      id: _id('p'),
      firstName: gender == 'male' ? 'Nouveau' : 'Nouvelle',
      lastName: gender == 'male' ? 'frère' : 'sœur',
      gender: gender,
      familyCode: person.familyCode,
      fatherId: person.fatherId,
      motherId: person.motherId,
      parents: person.parents,
    );
    return _withPeople(
      data,
      [sibling],
      gender == 'male' ? 'add_brother' : 'add_sister',
      actorRole,
      person.id,
    );
  }

  FamilyTreeData addSpouse(
    FamilyTreeData data,
    Person person, {
    String actorRole = '',
  }) {
    final spouse = Person(
      id: _id('p'),
      firstName: 'Nouveau',
      lastName: 'conjoint',
      gender: '',
      familyCode: person.familyCode,
      spouseIds: [person.id],
      spouses: [person.id],
      marriageType: person.marriageType,
    );
    final updatedPerson = person.copyWith(
      spouseIds: {...person.spouseIds, spouse.id}.toList(),
      spouses: {...person.spouses, spouse.id}.toList(),
    );
    final relation = MarriageRelation(
      id: _id('marriage'),
      personId: person.id,
      spouseId: spouse.id,
      marriageType: person.marriageType,
      order: data.marriageRelations.length + 1,
    );
    return _withPeople(
      data.copyWith(marriageRelations: [...data.marriageRelations, relation]),
      [spouse, updatedPerson],
      'add_spouse',
      actorRole,
      person.id,
    );
  }

  FamilyTreeData linkExistingPerson(
    FamilyTreeData data,
    Person base,
    Person existing, {
    required String relationship,
    String actorRole = '',
  }) {
    if (base.id == existing.id) {
      throw StateError('invalid_relationship');
    }
    if ((relationship == 'father' || relationship == 'mother') &&
        _isDescendant(data, base.id, existing.id)) {
      throw StateError('invalid_relationship_cycle');
    }
    if (relationship == 'child' && _isDescendant(data, existing.id, base.id)) {
      throw StateError('invalid_relationship_cycle');
    }
    if (relationship == 'spouse' &&
        (_isDescendant(data, base.id, existing.id) ||
            _isDescendant(data, existing.id, base.id))) {
      throw StateError('invalid_spouse_descendant_relationship');
    }
    return switch (relationship) {
      'father' => _withPeople(
        data,
        [
          base.copyWith(
            fatherId: existing.id,
            parents: {...base.parents, existing.id}.toList(),
          ),
          existing.copyWith(
            childrenIds: {...existing.childrenIds, base.id}.toList(),
            children: {...existing.children, base.id}.toList(),
          ),
        ],
        'link_father',
        actorRole,
        base.id,
      ),
      'mother' => _withPeople(
        data,
        [
          base.copyWith(
            motherId: existing.id,
            parents: {...base.parents, existing.id}.toList(),
          ),
          existing.copyWith(
            childrenIds: {...existing.childrenIds, base.id}.toList(),
            children: {...existing.children, base.id}.toList(),
          ),
        ],
        'link_mother',
        actorRole,
        base.id,
      ),
      'child' => _withPeople(
        data,
        [
          base.copyWith(
            childrenIds: {...base.childrenIds, existing.id}.toList(),
            children: {...base.children, existing.id}.toList(),
          ),
          existing.copyWith(
            fatherId: _isMale(base) ? base.id : existing.fatherId,
            motherId: _isFemale(base) ? base.id : existing.motherId,
            parents: {...existing.parents, base.id}.toList(),
          ),
        ],
        'link_child',
        actorRole,
        base.id,
      ),
      'spouse' => _linkSpouse(data, base, existing, actorRole),
      _ => data,
    };
  }

  Person? fatherOf(FamilyTreeData data, Person person) {
    final id = person.fatherId.isNotEmpty
        ? person.fatherId
        : _parentFallback(data, person, male: true);
    return _byId(data, id);
  }

  Person? motherOf(FamilyTreeData data, Person person) {
    final id = person.motherId.isNotEmpty
        ? person.motherId
        : _parentFallback(data, person, male: false);
    return _byId(data, id);
  }

  List<Person> spousesOf(FamilyTreeData data, Person person) {
    final relationIds =
        data.marriageRelations
            .where(
              (relation) =>
                  relation.personId == person.id ||
                  relation.spouseId == person.id,
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final ids = [
      ...person.spouseIds,
      ...person.spouses,
      ...relationIds.map(
        (relation) => relation.personId == person.id
            ? relation.spouseId
            : relation.personId,
      ),
    ];
    return _uniquePeople(data, ids);
  }

  List<Person> childrenOf(FamilyTreeData data, Person person) {
    final ids = [
      ...person.childrenIds,
      ...person.children,
      ...data.people
          .where(
            (candidate) =>
                candidate.fatherId == person.id ||
                candidate.motherId == person.id ||
                candidate.parents.contains(person.id),
          )
          .map((candidate) => candidate.id),
    ];
    return _uniquePeople(data, ids);
  }

  FamilyTreeData normalizeRelationships(FamilyTreeData data) {
    final normalized = <String, Person>{};

    for (final person in data.people) {
      final spouseIds = _validIds(
        data,
        {...person.spouseIds, ...person.spouses}..remove(person.id),
      );
      final parentIds = _validIds(
        data,
        {
          if (person.fatherId.isNotEmpty) person.fatherId,
          if (person.motherId.isNotEmpty) person.motherId,
          ...person.parents,
        }..remove(person.id),
      );
      final childrenIds = _validIds(
        data,
        {...person.childrenIds, ...person.children}
          ..removeAll({person.id, ...spouseIds}),
      );

      normalized[person.id] = person.copyWith(
        parents: parentIds,
        spouseIds: spouseIds,
        spouses: spouseIds,
        childrenIds: childrenIds,
        children: childrenIds,
      );
    }

    for (final relation in data.marriageRelations) {
      if (relation.personId == relation.spouseId) continue;
      final first = normalized[relation.personId];
      final second = normalized[relation.spouseId];
      if (first == null || second == null) continue;
      normalized[first.id] = first.copyWith(
        spouseIds: {...first.spouseIds, second.id}.toList(),
        spouses: {...first.spouses, second.id}.toList(),
        childrenIds: first.childrenIds.where((id) => id != second.id).toList(),
        children: first.children.where((id) => id != second.id).toList(),
      );
      normalized[second.id] = second.copyWith(
        spouseIds: {...second.spouseIds, first.id}.toList(),
        spouses: {...second.spouses, first.id}.toList(),
        childrenIds: second.childrenIds.where((id) => id != first.id).toList(),
        children: second.children.where((id) => id != first.id).toList(),
      );
    }

    for (final child in normalized.values.toList()) {
      final parentIds = {
        if (child.fatherId.isNotEmpty) child.fatherId,
        if (child.motherId.isNotEmpty) child.motherId,
        ...child.parents,
      }..remove(child.id);
      normalized[child.id] = child.copyWith(parents: parentIds.toList());
      for (final parentId in parentIds) {
        final parent = normalized[parentId];
        if (parent == null) continue;
        normalized[parentId] = parent.copyWith(
          childrenIds: {...parent.childrenIds, child.id}.toList(),
          children: {...parent.children, child.id}.toList(),
        );
      }
    }

    final next = data.copyWith(
      people: data.people.map((person) => normalized[person.id]!).toList(),
    );
    final errors = const GenealogyLayoutService().validateRelationshipGraph(
      next,
    );
    if (errors.isNotEmpty) {
      throw StateError('invalid_relationship_graph: ${errors.join(', ')}');
    }
    return next;
  }

  List<Person> siblingsOf(FamilyTreeData data, Person person) {
    final parentIds = {
      if (person.fatherId.isNotEmpty) person.fatherId,
      if (person.motherId.isNotEmpty) person.motherId,
      ...person.parents,
    };
    if (parentIds.isEmpty) return const [];
    return data.people
        .where(
          (candidate) =>
              candidate.id != person.id &&
              ({
                if (candidate.fatherId.isNotEmpty) candidate.fatherId,
                if (candidate.motherId.isNotEmpty) candidate.motherId,
                ...candidate.parents,
              }).intersection(parentIds).isNotEmpty,
        )
        .toList();
  }

  Person? _byId(FamilyTreeData data, String id) {
    if (id.isEmpty) return null;
    for (final person in data.people) {
      if (person.id == id) return person;
    }
    return null;
  }

  String _parentFallback(
    FamilyTreeData data,
    Person person, {
    required bool male,
  }) {
    for (final id in person.parents) {
      final parent = _byId(data, id);
      final gender = parent?.gender.toLowerCase();
      if (male && (gender == 'male' || gender == 'm' || gender == 'homme')) {
        return id;
      }
      if (!male && (gender == 'female' || gender == 'f' || gender == 'femme')) {
        return id;
      }
    }
    if (person.parents.isEmpty) return '';
    return male ? person.parents.last : person.parents.first;
  }

  List<Person> _uniquePeople(FamilyTreeData data, Iterable<String> ids) {
    final seen = <String>{};
    final people = <Person>[];
    for (final id in ids) {
      if (!seen.add(id)) continue;
      final person = _byId(data, id);
      if (person != null) people.add(person);
    }
    return people;
  }

  FamilyTreeData _linkSpouse(
    FamilyTreeData data,
    Person base,
    Person existing,
    String actorRole,
  ) {
    if (base.id == existing.id ||
        _isDescendant(data, base.id, existing.id) ||
        _isDescendant(data, existing.id, base.id)) {
      throw StateError('invalid_spouse_descendant_relationship');
    }
    final relation = MarriageRelation(
      id: _id('marriage'),
      personId: base.id,
      spouseId: existing.id,
      marriageType: base.marriageType,
      order: data.marriageRelations.length + 1,
    );
    return _withPeople(
      data.copyWith(marriageRelations: [...data.marriageRelations, relation]),
      [
        base.copyWith(
          spouseIds: {...base.spouseIds, existing.id}.toList(),
          spouses: {...base.spouses, existing.id}.toList(),
        ),
        existing.copyWith(
          spouseIds: {...existing.spouseIds, base.id}.toList(),
          spouses: {...existing.spouses, base.id}.toList(),
        ),
      ],
      'link_spouse',
      actorRole,
      base.id,
    );
  }

  FamilyTreeData _withPeople(
    FamilyTreeData data,
    List<Person> changed,
    String action,
    String actorRole,
    String personId,
  ) {
    final byId = {for (final person in data.people) person.id: person};
    for (final person in changed) {
      byId[person.id] = person;
    }
    final next = data.copyWith(
      people: byId.values.toList(),
      auditLog: [
        ...data.auditLog,
        AuditLog(
          id: 'log${DateTime.now().microsecondsSinceEpoch}',
          date: DateTime.now().toIso8601String(),
          action: action,
          actorRole: actorRole,
          personId: personId,
          description: action,
        ),
      ],
    );
    return normalizeRelationships(next);
  }

  void _assertCanBeParent(
    FamilyTreeData data,
    String parentId,
    String childId,
  ) {
    if (parentId == childId || _isDescendant(data, childId, parentId)) {
      throw StateError('invalid_relationship_cycle');
    }
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
    final ancestor = _byId(data, ancestorId);
    if (ancestor == null) return false;
    for (final child in childrenOf(data, ancestor)) {
      if (child.id == descendantId ||
          _isDescendant(data, child.id, descendantId, seen)) {
        return true;
      }
    }
    return false;
  }

  List<String> _validIds(FamilyTreeData data, Iterable<String> ids) {
    final byId = {for (final person in data.people) person.id};
    return ids.where(byId.contains).toSet().toList();
  }

  bool _isMale(Person person) {
    final gender = person.gender.toLowerCase();
    return gender == 'male' || gender == 'm' || gender == 'homme';
  }

  bool _isFemale(Person person) {
    final gender = person.gender.toLowerCase();
    return gender == 'female' || gender == 'f' || gender == 'femme';
  }

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';
}
