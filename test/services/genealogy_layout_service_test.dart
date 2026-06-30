import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/family_relation_service.dart';
import 'package:ayivonpome/services/genealogy_layout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps spouses on the same generation after adding a father', () {
    const service = FamilyRelationService();
    const layout = GenealogyLayoutService();
    final data = FamilyTreeData(
      people: const [
        Person(
          id: 'ama',
          firstName: 'Ama',
          gender: 'female',
          spouseIds: ['kossi'],
          spouses: ['kossi'],
        ),
        Person(
          id: 'kossi',
          firstName: 'Kossi',
          gender: 'male',
          spouseIds: ['ama'],
          spouses: ['ama'],
        ),
      ],
      marriageRelations: const [
        MarriageRelation(id: 'm1', personId: 'ama', spouseId: 'kossi'),
      ],
    );

    final next = service.addFather(data, data.people.first);
    final generations = layout.computeGenerations(next);
    final father = next.people.firstWhere(
      (person) => person.id.startsWith('p'),
    );

    expect(generations[father.id], 0);
    expect(generations['ama'], 1);
    expect(generations['kossi'], 1);
  });

  test('rejects spouse relationships between ancestors and descendants', () {
    const service = FamilyRelationService();
    final data = FamilyTreeData(
      people: const [
        Person(id: 'parent', childrenIds: ['child'], children: ['child']),
        Person(id: 'child', fatherId: 'parent', parents: ['parent']),
      ],
    );

    expect(
      () => service.linkExistingPerson(
        data,
        data.people.first,
        data.people.last,
        relationship: 'spouse',
      ),
      throwsStateError,
    );
  });

  test('rejects linking a descendant as father', () {
    const service = FamilyRelationService();
    final data = FamilyTreeData(
      people: const [
        Person(id: 'parent', childrenIds: ['child'], children: ['child']),
        Person(id: 'child', fatherId: 'parent', parents: ['parent']),
      ],
    );

    expect(
      () => service.linkExistingPerson(
        data,
        data.people.first,
        data.people.last,
        relationship: 'father',
      ),
      throwsStateError,
    );
  });
}
