import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/marriage_service.dart';

void main() {
  group('MarriageService', () {
    const service = MarriageService();
    const ama = Person(id: 'p001', firstName: 'Ama', lastName: 'Amouzou');
    const michel = Person(id: 'p002', firstName: 'Michel', lastName: 'Amouzou');
    const relation = MarriageRelation(
      id: 'marriage001',
      personId: 'p001',
      spouseId: 'p002',
      status: 'active',
      marriageDate: '1985-02-01',
    );
    const data = FamilyTreeData(
      people: [ama, michel],
      marriageRelations: [relation],
    );

    test('declares divorce and exposes former spouses', () {
      final updated = service.declareDivorce(
        data,
        relation,
        divorceDate: '2001-06-15',
        notes: 'Accord familial',
      );

      final divorced = updated.marriageRelations.single;
      expect(divorced.status, 'divorced');
      expect(divorced.divorceDate, '2001-06-15');
      expect(divorced.endDate, '2001-06-15');
      expect(divorced.notes, 'Accord familial');
      expect(service.getFormerSpouses(updated, ama), [michel]);
    });

    test('restores a divorced marriage without deleting the relation', () {
      final divorced = service
          .declareDivorce(data, relation, divorceDate: '2001-06-15')
          .marriageRelations
          .single;

      final restored = service.restoreMarriage(
        data.copyWith(marriageRelations: [divorced]),
        divorced,
      );

      expect(restored.marriageRelations, hasLength(1));
      expect(restored.marriageRelations.single.status, 'active');
      expect(restored.marriageRelations.single.divorceDate, isEmpty);
      expect(restored.marriageRelations.single.endDate, isEmpty);
    });
  });

  test('MarriageRelation serializes divorceDate', () {
    const relation = MarriageRelation(
      id: 'marriage001',
      personId: 'p001',
      spouseId: 'p002',
      status: 'divorced',
      divorceDate: '2001-06-15',
    );

    final parsed = MarriageRelation.fromJson(relation.toJson());

    expect(parsed.divorceDate, '2001-06-15');
    expect(parsed.status, 'divorced');
  });
}
