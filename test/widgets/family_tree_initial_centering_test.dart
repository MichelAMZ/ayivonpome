import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/widgets/family_tree_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parent = Person(id: 'parent', firstName: 'Parent', lastName: 'Ayivon');
  const child = Person(id: 'child', firstName: 'Enfant', lastName: 'Ayivon');

  test('first structural data refresh requests an automatic recenter', () {
    const oldData = FamilyTreeData(people: [parent]);
    const newData = FamilyTreeData(
      people: [
        parent,
        Person(
          id: 'child',
          firstName: 'Enfant',
          lastName: 'Ayivon',
          fatherId: 'parent',
        ),
      ],
    );

    expect(
      shouldRecenterTreeAfterInitialDataUpdate(
        oldData: oldData,
        newData: newData,
        hasAlreadyRecentered: false,
      ),
      isTrue,
    );
  });

  test('non structural data refresh does not move the tree', () {
    const oldData = FamilyTreeData(people: [parent, child]);
    const newData = FamilyTreeData(people: [parent, child]);

    expect(
      shouldRecenterTreeAfterInitialDataUpdate(
        oldData: oldData,
        newData: newData,
        hasAlreadyRecentered: false,
      ),
      isFalse,
    );
  });

  test('only one initial data refresh can trigger recentering', () {
    const oldData = FamilyTreeData(people: [parent]);
    const newData = FamilyTreeData(people: [parent, child]);

    expect(
      shouldRecenterTreeAfterInitialDataUpdate(
        oldData: oldData,
        newData: newData,
        hasAlreadyRecentered: true,
      ),
      isFalse,
    );
  });
}
