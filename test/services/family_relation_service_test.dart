import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/family_relation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FamilyRelationService linkExistingPerson', () {
    const service = FamilyRelationService();
    const child = Person(id: 'p001', firstName: 'Akouvi');
    const father = Person(id: 'p002', firstName: 'Koffi', gender: 'male');
    const mother = Person(id: 'p003', firstName: 'Ama', gender: 'female');
    const spouse = Person(id: 'p004', firstName: 'Kossi');

    test('links an existing father reciprocally without duplicates', () {
      final data = const FamilyTreeData(people: [child, father]);

      final updated = service.linkExistingPerson(
        data,
        child,
        father,
        relationship: 'father',
        actorRole: 'editor',
      );

      final updatedChild = updated.people.firstWhere((p) => p.id == child.id);
      final updatedFather = updated.people.firstWhere((p) => p.id == father.id);
      expect(updatedChild.fatherId, father.id);
      expect(updatedChild.parents, [father.id]);
      expect(updatedFather.childrenIds, [child.id]);
      expect(updatedFather.children, [child.id]);

      final repeated = service.linkExistingPerson(
        updated,
        updatedChild,
        updatedFather,
        relationship: 'father',
        actorRole: 'editor',
      );
      final repeatedFather = repeated.people.firstWhere(
        (p) => p.id == father.id,
      );
      expect(repeatedFather.childrenIds, [child.id]);
    });

    test('links an existing mother reciprocally', () {
      final updated = service.linkExistingPerson(
        const FamilyTreeData(people: [child, mother]),
        child,
        mother,
        relationship: 'mother',
        actorRole: 'editor',
      );

      final updatedChild = updated.people.firstWhere((p) => p.id == child.id);
      final updatedMother = updated.people.firstWhere((p) => p.id == mother.id);
      expect(updatedChild.motherId, mother.id);
      expect(updatedChild.parents, [mother.id]);
      expect(updatedMother.childrenIds, [child.id]);
      expect(updatedMother.children, [child.id]);
    });

    test('links an existing child reciprocally', () {
      final updated = service.linkExistingPerson(
        const FamilyTreeData(people: [father, child]),
        father,
        child,
        relationship: 'child',
        actorRole: 'editor',
      );

      final updatedChild = updated.people.firstWhere((p) => p.id == child.id);
      final updatedFather = updated.people.firstWhere((p) => p.id == father.id);
      expect(updatedChild.fatherId, father.id);
      expect(updatedChild.parents, [father.id]);
      expect(updatedFather.childrenIds, [child.id]);
      expect(updatedFather.children, [child.id]);
    });

    test('links an existing spouse through one marriage relation', () {
      final updated = service.linkExistingPerson(
        const FamilyTreeData(people: [child, spouse]),
        child,
        spouse,
        relationship: 'spouse',
        actorRole: 'editor',
      );

      expect(updated.marriageRelations, hasLength(1));
      expect(updated.people.firstWhere((p) => p.id == child.id).spouseIds, [
        spouse.id,
      ]);
      expect(updated.people.firstWhere((p) => p.id == spouse.id).spouseIds, [
        child.id,
      ]);

      final repeated = service.linkExistingPerson(
        updated,
        updated.people.firstWhere((p) => p.id == child.id),
        updated.people.firstWhere((p) => p.id == spouse.id),
        relationship: 'spouse',
        actorRole: 'editor',
      );
      expect(repeated.marriageRelations, hasLength(1));
    });

    test('rejects self links, cycles and silent parent replacement', () {
      expect(
        () => service.linkExistingPerson(
          const FamilyTreeData(people: [child]),
          child,
          child,
          relationship: 'father',
        ),
        throwsStateError,
      );

      final withParent = const FamilyTreeData(
        people: [
          Person(
            id: 'p001',
            firstName: 'Akouvi',
            fatherId: 'p002',
            parents: ['p002'],
          ),
          father,
          Person(id: 'p005', firstName: 'Autre père', gender: 'male'),
        ],
      );
      expect(
        () => service.linkExistingPerson(
          withParent,
          withParent.people.first,
          withParent.people.last,
          relationship: 'father',
        ),
        throwsStateError,
      );

      final cycleData = const FamilyTreeData(
        people: [
          Person(
            id: 'p001',
            firstName: 'Akouvi',
            fatherId: 'p002',
            parents: ['p002'],
          ),
          Person(id: 'p002', firstName: 'Koffi', childrenIds: ['p001']),
        ],
      );
      expect(
        () => service.linkExistingPerson(
          cycleData,
          cycleData.people.last,
          cycleData.people.first,
          relationship: 'father',
        ),
        throwsStateError,
      );
    });
  });
}
