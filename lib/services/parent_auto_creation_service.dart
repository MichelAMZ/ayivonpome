import '../models/audit_log.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';

enum ParentRole { father, mother }

enum ParentSimilarityLevel { strong, medium, weak }

class ParentDraft {
  const ParentDraft({
    required this.role,
    this.existingPersonId = '',
    this.firstName = '',
    this.lastName = '',
    this.birthLastName = '',
    this.maritalLastName = '',
    this.birthDate = '',
    this.deathDate = '',
    this.photo = '',
    this.country = '',
    this.city = '',
    this.birthPlace = '',
  });

  final ParentRole role;
  final String existingPersonId;
  final String firstName;
  final String lastName;
  final String birthLastName;
  final String maritalLastName;
  final String birthDate;
  final String deathDate;
  final String photo;
  final String country;
  final String city;
  final String birthPlace;

  bool get hasIdentity =>
      existingPersonId.trim().isNotEmpty ||
      firstName.trim().isNotEmpty ||
      lastName.trim().isNotEmpty ||
      birthLastName.trim().isNotEmpty;

  bool get createsNewPerson =>
      existingPersonId.trim().isEmpty &&
      (firstName.trim().isNotEmpty ||
          lastName.trim().isNotEmpty ||
          birthLastName.trim().isNotEmpty);

  String get displayName {
    final name = role == ParentRole.mother && birthLastName.trim().isNotEmpty
        ? '$firstName $birthLastName'
        : '$firstName $lastName';
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class ParentMatch {
  const ParentMatch({required this.person, required this.level});

  final Person person;
  final ParentSimilarityLevel level;
}

class ParentAutoCreationResult {
  const ParentAutoCreationResult({
    required this.data,
    required this.createdParents,
    required this.updatedParents,
    required this.createdMarriageRelations,
    required this.auditLogs,
  });

  final FamilyTreeData data;
  final List<Person> createdParents;
  final List<Person> updatedParents;
  final List<MarriageRelation> createdMarriageRelations;
  final List<AuditLog> auditLogs;
}

class ParentAutoCreationService {
  const ParentAutoCreationService();

  List<ParentMatch> search(FamilyTreeData data, ParentDraft draft) {
    if (!draft.hasIdentity) return const [];
    final matches = <ParentMatch>[];
    for (final person in data.people) {
      if (!_matchesGender(person, draft.role)) continue;
      final level = similarity(person, draft);
      if (level != null) {
        matches.add(ParentMatch(person: person, level: level));
      }
    }
    matches.sort((a, b) => a.level.index.compareTo(b.level.index));
    return matches;
  }

  ParentSimilarityLevel? similarity(Person person, ParentDraft draft) {
    final first = _same(person.firstName, draft.firstName);
    final last = _same(_bestLastName(person), _bestLastName(draft));
    final birth =
        draft.birthDate.trim().isNotEmpty &&
        person.birthDate.trim() == draft.birthDate.trim();
    final place =
        draft.birthPlace.trim().isNotEmpty &&
        _same(person.birthPlace, draft.birthPlace);

    if (first && last && (birth || place)) return ParentSimilarityLevel.strong;
    if (first && last) return ParentSimilarityLevel.medium;
    if ((first || last) && _containsNameToken(person, draft)) {
      return ParentSimilarityLevel.weak;
    }
    return null;
  }

  ParentAutoCreationResult apply({
    required FamilyTreeData data,
    required Person child,
    ParentDraft? fatherDraft,
    ParentDraft? motherDraft,
    bool linkParentsAsCouple = false,
    String parentCoupleStatus = 'unknown',
    String actorRole = '',
    String adminId = '',
  }) {
    final peopleById = {for (final person in data.people) person.id: person};
    var nextChild = child;
    final createdParents = <Person>[];
    final updatedParents = <Person>[];
    final auditLogs = <AuditLog>[];

    void resolve(ParentDraft draft) {
      if (!draft.hasIdentity) return;
      final relationship = draft.role == ParentRole.father
          ? 'father'
          : 'mother';
      final parent = draft.existingPersonId.trim().isNotEmpty
          ? peopleById[draft.existingPersonId.trim()]
          : _createParent(draft, nextChild);
      if (parent == null) {
        throw StateError('parent_not_found');
      }
      if (parent.id == nextChild.id) {
        throw StateError('invalid_relationship');
      }
      _assertNotDescendant(peopleById.values, nextChild.id, parent.id);

      final updatedParent = parent.copyWith(
        childrenIds: {...parent.childrenIds, nextChild.id}.toList(),
        children: {...parent.children, nextChild.id}.toList(),
      );
      nextChild = nextChild.copyWith(
        fatherId: draft.role == ParentRole.father
            ? parent.id
            : nextChild.fatherId,
        motherId: draft.role == ParentRole.mother
            ? parent.id
            : nextChild.motherId,
        parents: {...nextChild.parents, parent.id}.toList(),
      );
      peopleById[parent.id] = updatedParent;
      peopleById[nextChild.id] = nextChild;

      if (draft.createsNewPerson) {
        createdParents.add(updatedParent);
        auditLogs.add(
          _log(
            'auto_${relationship}_created',
            nextChild.id,
            nextChild.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${updatedParent.fullName} -> ${nextChild.fullName}',
          ),
        );
      } else {
        updatedParents.add(updatedParent);
        auditLogs.add(
          _log(
            '${relationship}_linked',
            nextChild.id,
            nextChild.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${updatedParent.fullName} -> ${nextChild.fullName}',
          ),
        );
      }
    }

    if (fatherDraft != null) resolve(fatherDraft);
    if (motherDraft != null) resolve(motherDraft);

    final createdRelations = <MarriageRelation>[];
    if (linkParentsAsCouple &&
        nextChild.fatherId.isNotEmpty &&
        nextChild.motherId.isNotEmpty &&
        !_hasMarriage(data, nextChild.fatherId, nextChild.motherId)) {
      final relation = MarriageRelation(
        id: 'marriage${DateTime.now().microsecondsSinceEpoch}',
        personId: nextChild.fatherId,
        spouseId: nextChild.motherId,
        marriageType: parentCoupleStatus,
        status: parentCoupleStatus,
        order: data.marriageRelations.length + 1,
        createdAt: DateTime.now().toIso8601String(),
        updatedBy: adminId,
      );
      createdRelations.add(relation);
      final father = peopleById[nextChild.fatherId];
      final mother = peopleById[nextChild.motherId];
      if (father != null && mother != null) {
        peopleById[father.id] = father.copyWith(
          spouseIds: {...father.spouseIds, mother.id}.toList(),
          spouses: {...father.spouses, mother.id}.toList(),
        );
        peopleById[mother.id] = mother.copyWith(
          spouseIds: {...mother.spouseIds, father.id}.toList(),
          spouses: {...mother.spouses, father.id}.toList(),
        );
      }
      auditLogs.add(
        _log(
          'parents_couple_linked',
          nextChild.id,
          nextChild.familyCode,
          actorRole: actorRole,
          adminId: adminId,
          description: '${nextChild.fatherId}-${nextChild.motherId}',
        ),
      );
    }

    return ParentAutoCreationResult(
      data: data.copyWith(
        people: data.people.map((person) => peopleById[person.id]!).toList(),
        marriageRelations: [...data.marriageRelations, ...createdRelations],
      ),
      createdParents: createdParents,
      updatedParents: updatedParents,
      createdMarriageRelations: createdRelations,
      auditLogs: auditLogs,
    );
  }

  Person _createParent(ParentDraft draft, Person child) {
    final now = DateTime.now().toIso8601String();
    final lastName = draft.role == ParentRole.mother
        ? (draft.maritalLastName.trim().isNotEmpty
              ? draft.maritalLastName.trim()
              : draft.birthLastName.trim())
        : draft.lastName.trim();
    return Person(
      id: 'p${DateTime.now().microsecondsSinceEpoch}',
      firstName: draft.firstName.trim(),
      lastName: lastName,
      birthLastName: draft.role == ParentRole.mother
          ? draft.birthLastName.trim()
          : '',
      gender: draft.role == ParentRole.father ? 'male' : 'female',
      birthDate: draft.birthDate.trim(),
      deathDate: draft.deathDate.trim(),
      birthPlace: draft.birthPlace.trim(),
      currentCountry: draft.country.trim(),
      currentCity: draft.city.trim(),
      photo: draft.photo.trim(),
      familyCode: child.familyCode,
      familyId: child.familyId,
      childrenIds: [child.id],
      children: [child.id],
      notes: 'Profil à compléter',
      createdAt: now,
      updatedAt: now,
      updatedBy: 'auto_parent_creation',
      isTemporaryProfile: true,
      profileNeedsCompletion: true,
    );
  }

  bool _matchesGender(Person person, ParentRole role) {
    final gender = _normalize(person.gender);
    if (role == ParentRole.father) {
      return gender.isEmpty ||
          gender == 'male' ||
          gender == 'm' ||
          gender == 'homme';
    }
    return gender.isEmpty ||
        gender == 'female' ||
        gender == 'f' ||
        gender == 'femme';
  }

  String _bestLastName(Object value) {
    if (value is ParentDraft) {
      if (value.role == ParentRole.mother &&
          value.birthLastName.trim().isNotEmpty) {
        return value.birthLastName;
      }
      return value.lastName;
    }
    final person = value as Person;
    return person.birthLastName.trim().isNotEmpty
        ? person.birthLastName
        : person.lastName;
  }

  bool _containsNameToken(Person person, ParentDraft draft) {
    final haystack = _normalize(
      '${person.firstName} ${person.lastName} ${person.birthLastName}',
    );
    final tokens = _normalize(
      '${draft.firstName} ${_bestLastName(draft)}',
    ).split(' ').where((token) => token.length >= 3);
    return tokens.any(haystack.contains);
  }

  bool _same(String first, String second) {
    final a = _normalize(first);
    final b = _normalize(second);
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  String _normalize(String value) {
    const accents = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasMarriage(FamilyTreeData data, String firstId, String secondId) {
    return data.marriageRelations.any(
      (relation) =>
          (relation.personId == firstId && relation.spouseId == secondId) ||
          (relation.personId == secondId && relation.spouseId == firstId),
    );
  }

  void _assertNotDescendant(
    Iterable<Person> people,
    String childId,
    String parentId,
  ) {
    final byId = {for (final person in people) person.id: person};
    bool visit(String currentId, Set<String> seen) {
      if (!seen.add(currentId)) return false;
      final current = byId[currentId];
      if (current == null) return false;
      if (current.childrenIds.contains(parentId) ||
          current.children.contains(parentId)) {
        return true;
      }
      return [
        ...current.childrenIds,
        ...current.children,
      ].any((id) => visit(id, seen));
    }

    if (visit(childId, <String>{})) {
      throw StateError('invalid_relationship_cycle');
    }
  }

  AuditLog _log(
    String action,
    String personId,
    String familyCode, {
    String actorRole = '',
    String adminId = '',
    String description = '',
  }) {
    return AuditLog(
      id: 'log${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now().toIso8601String(),
      action: action,
      personId: personId,
      familyCode: familyCode,
      actorRole: actorRole,
      adminId: adminId,
      description: description,
    );
  }
}
