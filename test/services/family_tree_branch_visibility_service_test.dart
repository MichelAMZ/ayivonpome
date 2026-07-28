import 'package:ayivonpome/models/family_link.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/family_tree_branch_visibility_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = FamilyTreeBranchVisibilityService();

  const root = Person(id: 'root', firstName: 'Racine');
  const child = Person(id: 'child', fatherId: 'root');
  const grandchild = Person(id: 'grandchild', motherId: 'child');
  const childSpouse = Person(id: 'child-spouse', spouseIds: ['child']);
  const siblingBranch = Person(id: 'sibling', fatherId: 'other-root');
  const otherRoot = Person(id: 'other-root');
  const data = FamilyTreeData(
    mainFamilyCode: 'ayivon',
    people: [root, child, grandchild, childSpouse, otherRoot, siblingBranch],
    marriageRelations: [
      MarriageRelation(
        id: 'marriage',
        personId: 'child',
        spouseId: 'child-spouse',
      ),
    ],
    familyLinks: [
      FamilyLink(id: 'inside', fromPersonId: 'child', toPersonId: 'grandchild'),
      FamilyLink(
        id: 'outside',
        fromPersonId: 'other-root',
        toPersonId: 'sibling',
      ),
    ],
  );

  test('all branches are visible by default', () {
    final visible = service.visibleData(data, const {});
    expect(visible.people, hasLength(data.people.length));
    expect(visible.marriageRelations, hasLength(1));
  });

  test('collapse keeps root and hides descendants and exclusive spouse', () {
    final visible = service.visibleData(data, {'root'});
    final visibleIds = visible.people.map((person) => person.id).toSet();

    expect(visibleIds, contains('root'));
    expect(visibleIds, isNot(contains('child')));
    expect(visibleIds, isNot(contains('grandchild')));
    expect(visibleIds, isNot(contains('child-spouse')));
    expect(visibleIds, containsAll(['other-root', 'sibling']));
    expect(visible.marriageRelations, isEmpty);
    expect(visible.familyLinks.map((link) => link.id), ['outside']);
  });

  test('expand restores members and links without duplicates', () {
    final collapsed = service.visibleData(data, {'root'});
    final expanded = service.visibleData(data, const {});

    expect(collapsed.people, hasLength(3));
    expect(expanded.people.map((person) => person.id).toSet(), hasLength(6));
    expect(expanded.familyLinks, hasLength(2));
  });

  test('nested collapsed branches stay independently addressable', () {
    final hiddenByChild = service.hiddenMemberIds(data, {'child'});
    final hiddenByBoth = service.hiddenMemberIds(data, {'root', 'child'});

    expect(hiddenByChild, contains('grandchild'));
    expect(hiddenByChild, isNot(contains('child')));
    expect(hiddenByBoth, isNot(contains('root')));
    expect(hiddenByBoth, contains('child'));
  });

  test('a cyclic relationship cannot crash or include the root', () {
    const cyclic = [
      Person(id: 'a', fatherId: 'c'),
      Person(id: 'b', fatherId: 'a'),
      Person(id: 'c', fatherId: 'b'),
    ];

    expect(service.collectDescendantIds('a', cyclic), {'b', 'c'});
  });

  test('search identifies every collapsed ancestor to reopen', () {
    expect(
      service.collapsedRootsHiding('grandchild', data, {'root', 'child'}),
      {'root', 'child'},
    );
  });

  test('collapsed state is persisted locally', () async {
    SharedPreferences.setMockInitialValues({});

    await service.save('ayivon', {'child', 'root'});
    final restored = await service.load('ayivon');

    expect(restored, {'child', 'root'});
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList(
        '${FamilyTreeBranchVisibilityService.storageKeyPrefix}ayivon',
      ),
      ['child', 'root'],
    );
  });
}
