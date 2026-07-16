import 'package:ayivonpome/features/family_tree/domain/errors/family_relationship_error.dart';
import 'package:ayivonpome/features/family_tree/domain/use_cases/link_existing_father.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkExistingFatherUseCase', () {
    const useCase = LinkExistingFatherUseCase();

    test('updates the child and father bidirectionally', () {
      const child = Person(id: 'p001', firstName: 'Akouvi');
      const father = Person(id: 'p002', firstName: 'Koffi', gender: 'male');

      final result = useCase(
        data: const FamilyTreeData(people: [child, father]),
        childId: child.id,
        fatherId: father.id,
      );

      final updatedChild = result.people.firstWhere(
        (item) => item.id == child.id,
      );
      final updatedFather = result.people.firstWhere(
        (item) => item.id == father.id,
      );
      expect(updatedChild.fatherId, father.id);
      expect(updatedChild.parents, [father.id]);
      expect(updatedFather.childrenIds, [child.id]);
      expect(updatedFather.children, [child.id]);
    });

    test('rejects silent father replacement', () {
      const child = Person(
        id: 'p001',
        firstName: 'Akouvi',
        fatherId: 'p002',
        parents: ['p002'],
      );

      expect(
        () => useCase(
          data: const FamilyTreeData(
            people: [
              child,
              Person(id: 'p002', firstName: 'Koffi'),
              Person(id: 'p003', firstName: 'Kodjo'),
            ],
          ),
          childId: child.id,
          fatherId: 'p003',
        ),
        throwsA(isA<ParentAlreadyAssigned>()),
      );
    });

    test('rejects genealogical cycles', () {
      const ancestor = Person(
        id: 'p001',
        firstName: 'Ancetre',
        childrenIds: ['p002'],
      );
      const descendant = Person(
        id: 'p002',
        firstName: 'Descendant',
        fatherId: 'p001',
        parents: ['p001'],
      );

      expect(
        () => useCase(
          data: const FamilyTreeData(people: [ancestor, descendant]),
          childId: ancestor.id,
          fatherId: descendant.id,
        ),
        throwsA(isA<RelationshipCycleDetected>()),
      );
    });
  });
}
