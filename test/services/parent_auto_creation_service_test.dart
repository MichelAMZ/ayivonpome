import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/parent_auto_creation_service.dart';

void main() {
  const service = ParentAutoCreationService();

  test('creates father and links both sides', () {
    const child = Person(id: 'child', firstName: 'Jean', familyCode: 'ayivon');
    final result = service.apply(
      data: const FamilyTreeData(people: [child]),
      child: child,
      fatherDraft: const ParentDraft(
        role: ParentRole.father,
        firstName: 'Koffi',
        lastName: 'Amouzou',
      ),
    );

    final updatedChild = result.data.people.firstWhere(
      (person) => person.id == 'child',
    );
    final father = result.createdParents.single;

    expect(father.gender, 'male');
    expect(father.childrenIds, contains('child'));
    expect(father.profileNeedsCompletion, isTrue);
    expect(updatedChild.fatherId, father.id);
    expect(updatedChild.parents, contains(father.id));
  });

  test('creates mother with birth and marital names', () {
    const child = Person(id: 'child', firstName: 'Afi', familyCode: 'ayivon');
    final result = service.apply(
      data: const FamilyTreeData(people: [child]),
      child: child,
      motherDraft: const ParentDraft(
        role: ParentRole.mother,
        firstName: 'Ama',
        birthLastName: 'Levonvi',
        maritalLastName: 'Ayivon',
      ),
    );

    final mother = result.createdParents.single;
    final updatedChild = result.data.people.firstWhere(
      (person) => person.id == 'child',
    );

    expect(mother.gender, 'female');
    expect(mother.lastName, 'Ayivon');
    expect(mother.birthLastName, 'Levonvi');
    expect(updatedChild.motherId, mother.id);
  });

  test('links an existing parent without creating duplicate', () {
    const child = Person(id: 'child', firstName: 'Jean');
    const parent = Person(id: 'parent', firstName: 'Koffi', gender: 'male');
    final result = service.apply(
      data: const FamilyTreeData(people: [child, parent]),
      child: child,
      fatherDraft: const ParentDraft(
        role: ParentRole.father,
        existingPersonId: 'parent',
      ),
    );

    final updatedParent = result.data.people.firstWhere(
      (person) => person.id == 'parent',
    );
    final updatedChild = result.data.people.firstWhere(
      (person) => person.id == 'child',
    );

    expect(result.createdParents, isEmpty);
    expect(updatedParent.childrenIds, contains('child'));
    expect(updatedChild.fatherId, 'parent');
  });

  test('detects similar names without case or accents', () {
    const existing = Person(
      id: 'p1',
      firstName: 'José',
      lastName: 'AMOUZOU',
      gender: 'male',
    );
    final matches = service.search(
      const FamilyTreeData(people: [existing]),
      const ParentDraft(
        role: ParentRole.father,
        firstName: 'jose',
        lastName: 'amouzou',
      ),
    );

    expect(matches, hasLength(1));
    expect(matches.single.level, ParentSimilarityLevel.medium);
  });
}
