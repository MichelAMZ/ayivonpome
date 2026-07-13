import '../models/family_tree_data.dart';
import '../models/family_tree_reference.dart';
import '../models/person.dart';

class LinkedFamilyTreeService {
  const LinkedFamilyTreeService(this.data);

  final FamilyTreeData data;

  bool hasLinkedFamilyTree(Person person) {
    final targetFamilyId = getLinkedFamilyId(person);
    if (targetFamilyId == null || !person.linkedTreeEnabled) return false;
    if (_sameFamily(targetFamilyId, _mainFamilyId)) return false;
    return data.people.any(
      (member) =>
          member.id != person.id &&
          _belongsToFamily(member, targetFamilyId) &&
          _isDirectlyRelatedToBridge(member, person),
    );
  }

  String? getLinkedFamilyId(Person person) {
    final explicitLink = _enabledLinksFor(person.id).firstOrNull;
    if (explicitLink != null) return explicitLink.targetFamilyId;
    final originFamilyId = person.originFamilyId.trim();
    if (originFamilyId.isNotEmpty) return originFamilyId;
    return null;
  }

  String linkedFamilyName(Person person) {
    final link = _enabledLinksFor(person.id).firstOrNull;
    if (link != null && link.targetFamilyName.trim().isNotEmpty) {
      return link.targetFamilyName.trim();
    }
    final familyId = getLinkedFamilyId(person);
    final family = data.families
        .where((item) => _sameFamily(item.id, familyId))
        .firstOrNull;
    if (family != null && family.name.trim().isNotEmpty) return family.name;
    final originName = person.originLastName;
    if (originName.isNotEmpty) return 'Famille $originName';
    return 'Famille liée';
  }

  FamilyTreeReference? referenceFor(Person person) {
    final link = _enabledLinksFor(person.id).firstOrNull;
    if (link != null) return link;
    final targetFamilyId = getLinkedFamilyId(person);
    if (targetFamilyId == null) return null;
    return FamilyTreeReference(
      id: 'auto-${person.id}-$targetFamilyId',
      personId: person.id,
      sourceFamilyId: _mainFamilyId,
      targetFamilyId: targetFamilyId,
      targetFamilyName: linkedFamilyName(person),
      relationshipType: 'originFamily',
      enabled: person.linkedTreeEnabled,
    );
  }

  List<Person> getLinkedFamilyMembers(
    String familyId, {
    String focusPersonId = '',
  }) {
    final byId = {for (final person in data.people) person.id: person};
    final included = <String>{};

    for (final person in data.people) {
      if (_belongsToFamily(person, familyId)) included.add(person.id);
    }

    final focus = byId[focusPersonId];
    if (focus != null) {
      included.add(focus.id);
      for (final id in [
        focus.fatherId,
        focus.motherId,
        ...focus.parents,
        ...focus.spouseIds,
        ...focus.spouses,
        ...focus.childrenIds,
        ...focus.children,
      ]) {
        if (id.isNotEmpty) included.add(id);
      }
    }

    var changed = true;
    while (changed) {
      changed = false;
      for (final person in data.people) {
        if (!included.contains(person.id)) continue;
        for (final id in [
          person.fatherId,
          person.motherId,
          ...person.parents,
          ...person.childrenIds,
          ...person.children,
        ]) {
          if (id.isNotEmpty && !included.contains(id)) {
            included.add(id);
            changed = true;
          }
        }
      }
    }

    return [
      for (final person in data.people)
        if (included.contains(person.id)) person,
    ];
  }

  FamilyTreeData buildLinkedFamilyTree({
    required String familyId,
    required String focusPersonId,
  }) {
    final people = getLinkedFamilyMembers(
      familyId,
      focusPersonId: focusPersonId,
    );
    final allowedIds = people.map((person) => person.id).toSet();
    return data.copyWith(
      people: people,
      marriageRelations: data.marriageRelations
          .where(
            (relation) =>
                allowedIds.contains(relation.personId) &&
                allowedIds.contains(relation.spouseId),
          )
          .toList(),
      mainFamilyCode: familyId,
    );
  }

  List<FamilyTreeReference> _enabledLinksFor(String personId) {
    return data.familyTreeLinks
        .where((link) => link.enabled && link.personId == personId)
        .toList();
  }

  bool _belongsToFamily(Person person, String familyId) {
    return _sameFamily(person.familyId, familyId) ||
        _sameFamily(person.originFamilyId, familyId) ||
        _sameFamily(person.familyCode, familyId);
  }

  bool _isDirectlyRelatedToBridge(Person member, Person bridge) {
    final bridgeParentIds = {
      bridge.fatherId,
      bridge.motherId,
      ...bridge.parents,
    }..removeWhere((id) => id.isEmpty);
    final memberParentIds = {
      member.fatherId,
      member.motherId,
      ...member.parents,
    }..removeWhere((id) => id.isEmpty);
    return bridge.fatherId == member.id ||
        bridge.motherId == member.id ||
        bridge.parents.contains(member.id) ||
        bridge.childrenIds.contains(member.id) ||
        bridge.children.contains(member.id) ||
        member.fatherId == bridge.id ||
        member.motherId == bridge.id ||
        member.parents.contains(bridge.id) ||
        member.childrenIds.contains(bridge.id) ||
        member.children.contains(bridge.id) ||
        memberParentIds.any(bridgeParentIds.contains);
  }

  bool _sameFamily(String? a, String? b) {
    return (a ?? '').trim().toLowerCase() == (b ?? '').trim().toLowerCase();
  }

  String get _mainFamilyId {
    final configured = data.mainFamilyCode.trim();
    final matched = data.families
        .where(
          (family) =>
              _sameFamily(family.id, configured) ||
              _sameFamily(family.code, configured),
        )
        .firstOrNull;
    if (matched != null && matched.id.trim().isNotEmpty) return matched.id;
    final primary = data.families.firstOrNull;
    if (primary != null && primary.id.trim().isNotEmpty) return primary.id;
    return data.mainFamilyCode;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
