import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/genealogy_statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts direct children and total descendants without duplicates', () {
    const data = FamilyTreeData(
      people: [
        Person(id: 'p1', firstName: 'Kossi', childrenIds: ['p2', 'p3']),
        Person(id: 'p2', firstName: 'Child 1', childrenIds: ['p4', 'p5']),
        Person(id: 'p3', firstName: 'Child 2', childrenIds: ['p6']),
        Person(id: 'p4', firstName: 'Grandchild 1'),
        Person(id: 'p5', firstName: 'Grandchild 2'),
        Person(id: 'p6', firstName: 'Grandchild 3'),
      ],
    );
    final service = GenealogyStatisticsService(data);

    expect(service.getDirectChildrenCount('p1'), 2);
    expect(service.getTotalDescendantsCount('p1'), 5);
    expect(service.getAllDescendants('p1').map((person) => person.id), [
      'p2',
      'p4',
      'p5',
      'p3',
      'p6',
    ]);
  });

  test('protects descendant traversal from cycles', () {
    const data = FamilyTreeData(
      people: [
        Person(id: 'p1', firstName: 'Root', childrenIds: ['p2']),
        Person(id: 'p2', firstName: 'Child', childrenIds: ['p1']),
      ],
    );
    final service = GenealogyStatisticsService(data);

    expect(service.getDirectChildrenCount('p1'), 1);
    expect(service.getTotalDescendantsCount('p1'), 1);
    expect(service.getAllDescendants('p1').single.id, 'p2');
  });
}
