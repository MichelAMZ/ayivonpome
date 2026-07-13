import 'package:ayivonpome/models/family.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/family_tree_reference.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/linked_family_tree_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkedFamilyTreeService', () {
    test(
      'detects a linked origin tree when a related member belongs to it',
      () {
        final data = _data();
        final service = LinkedFamilyTreeService(data);
        final bridge = data.people.firstWhere((person) => person.id == 'p100');

        expect(service.hasLinkedFamilyTree(bridge), isTrue);
        expect(service.getLinkedFamilyId(bridge), 'family-levonvi');
        expect(service.linkedFamilyName(bridge), 'Famille Lévonvi');
      },
    );

    test('does not detect a linked tree without a related target member', () {
      final data = _data(
        people: const [
          Person(
            id: 'p100',
            firstName: 'Ama',
            lastName: 'Amouzou',
            birthLastName: 'Lévonvi',
            gender: 'female',
            familyId: 'family-ayivon',
            originFamilyId: 'family-levonvi',
            linkedTreeEnabled: true,
            spouseIds: ['p050'],
            childrenIds: ['p201'],
          ),
          Person(id: 'p050', firstName: 'Kossi', familyId: 'family-ayivon'),
          Person(id: 'p201', firstName: 'Enfant', familyId: 'family-ayivon'),
        ],
      );
      final service = LinkedFamilyTreeService(data);

      expect(service.hasLinkedFamilyTree(data.people.first), isFalse);
    });

    test('builds a filtered tree from the same person ids', () {
      final data = _data();
      final service = LinkedFamilyTreeService(data);

      final linked = service.buildLinkedFamilyTree(
        familyId: 'family-levonvi',
        focusPersonId: 'p100',
      );
      final ids = linked.people.map((person) => person.id).toSet();

      expect(ids, containsAll(['p100', 'p101', 'p102', 'p201']));
      expect(ids, isNot(contains('p999')));
      expect(
        linked.people.firstWhere((person) => person.id == 'p100'),
        same(data.people.first),
      );
    });
  });
}

FamilyTreeData _data({List<Person>? people}) {
  return FamilyTreeData(
    mainFamilyCode: 'family-ayivon',
    families: const [
      Family(id: 'family-ayivon', name: 'Famille AYIVON', code: 'AYIVON'),
      Family(id: 'family-levonvi', name: 'Famille Lévonvi', code: 'LEVONVI'),
    ],
    familyTreeLinks: const [
      FamilyTreeReference(
        id: 'tree-link-001',
        personId: 'p100',
        sourceFamilyId: 'family-ayivon',
        targetFamilyId: 'family-levonvi',
        targetFamilyName: 'Famille Lévonvi',
        relationshipType: 'originFamily',
        enabled: true,
      ),
    ],
    people:
        people ??
        const [
          Person(
            id: 'p100',
            firstName: 'Ama',
            lastName: 'Amouzou',
            birthLastName: 'Lévonvi',
            gender: 'female',
            familyId: 'family-ayivon',
            originFamilyId: 'family-levonvi',
            fatherId: 'p101',
            motherId: 'p102',
            spouseIds: ['p050'],
            childrenIds: ['p201'],
            linkedTreeEnabled: true,
            parents: ['p101', 'p102'],
            spouses: ['p050'],
            children: ['p201'],
          ),
          Person(
            id: 'p101',
            firstName: 'Kodjo',
            lastName: 'Lévonvi',
            familyId: 'family-levonvi',
            childrenIds: ['p100'],
            children: ['p100'],
          ),
          Person(
            id: 'p102',
            firstName: 'Akou',
            lastName: 'Lévonvi',
            familyId: 'family-levonvi',
            childrenIds: ['p100'],
            children: ['p100'],
          ),
          Person(
            id: 'p050',
            firstName: 'Kossi',
            lastName: 'Amouzou',
            familyId: 'family-ayivon',
            spouseIds: ['p100'],
            childrenIds: ['p201'],
            spouses: ['p100'],
            children: ['p201'],
          ),
          Person(
            id: 'p201',
            firstName: 'Enfant',
            lastName: 'Amouzou',
            familyId: 'family-ayivon',
            fatherId: 'p050',
            motherId: 'p100',
            parents: ['p050', 'p100'],
          ),
          Person(id: 'p999', firstName: 'Hors', familyId: 'family-ayivon'),
        ],
  );
}
