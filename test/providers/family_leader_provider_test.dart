import 'package:ayivonpome/models/family_honor.dart';
import 'package:ayivonpome/models/family_leadership.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/family_leader_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const root = Person(id: 'root', firstName: 'AYIVON', generation: 1);
  const child = Person(
    id: 'child',
    firstName: 'AKAKPO',
    generation: 2,
    parents: ['root'],
  );

  test('retrouve le chef configuré par son identifiant', () {
    const data = FamilyTreeData(
      familyLeadership: FamilyLeadership(currentLeaderPersonId: 'root'),
      people: [root, child],
    );

    expect(resolveFamilyLeader(data)?.id, 'root');
  });

  test(
    'utilise le patriarche si l’identifiant du chef est devenu obsolète',
    () {
      const data = FamilyTreeData(
        familyLeadership: FamilyLeadership(currentLeaderPersonId: 'legacy-id'),
        familyHonor: FamilyHonor(patriarchPersonId: 'child'),
        people: [root, child],
      );

      expect(resolveFamilyLeader(data)?.id, 'child');
    },
  );

  test('retrouve la racine après remplacement des identifiants de l’arbre', () {
    const data = FamilyTreeData(
      familyLeadership: FamilyLeadership(currentLeaderPersonId: 'legacy-id'),
      people: [child, root],
    );

    expect(resolveFamilyLeader(data)?.id, 'root');
  });

  test('respecte une absence volontaire de chef configuré', () {
    const data = FamilyTreeData(people: [root, child]);

    expect(resolveFamilyLeader(data), isNull);
  });
}
