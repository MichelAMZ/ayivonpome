import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/genealogy_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computes one-based generations from the root ancestor', () {
    const service = GenealogyGenerationService();
    const data = FamilyTreeData(
      people: [
        Person(id: 'koffi', firstName: 'Koffi', childrenIds: ['ama']),
        Person(
          id: 'ama',
          firstName: 'Ama',
          fatherId: 'koffi',
          childrenIds: ['michel'],
          spouseIds: ['kossi'],
        ),
        Person(id: 'kossi', firstName: 'Kossi', spouseIds: ['ama']),
        Person(
          id: 'michel',
          firstName: 'Michel',
          motherId: 'ama',
          childrenIds: ['david'],
        ),
        Person(
          id: 'david',
          firstName: 'David',
          fatherId: 'michel',
          childrenIds: ['sarah'],
        ),
        Person(id: 'sarah', firstName: 'Sarah', fatherId: 'david'),
      ],
      marriageRelations: [
        MarriageRelation(id: 'm1', personId: 'ama', spouseId: 'kossi'),
      ],
    );

    final generations = service.computeAllGenerations(data);
    final recalculated = service.recalculate(data);
    final ama = recalculated.people.firstWhere((person) => person.id == 'ama');
    final sarah = recalculated.people.firstWhere(
      (person) => person.id == 'sarah',
    );

    expect(service.getRootAncestor(data)?.id, 'koffi');
    expect(generations['koffi'], 1);
    expect(generations['ama'], 2);
    expect(generations['kossi'], 2);
    expect(generations['michel'], 3);
    expect(generations['david'], 4);
    expect(generations['sarah'], 5);
    expect(sarah.generation, 5);
    expect(service.generationDistance(ama, sarah), 3);
  });
}
