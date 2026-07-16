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

    test(
      'creates a reciprocal traditional union without duplicating spouses',
      () {
        final updated = service.upsertUnion(
          const FamilyTreeData(people: [ama, michel]),
          const MarriageRelation(
            id: '',
            familyId: 'ayivon',
            personId: 'p001',
            spouseId: 'p002',
            marriageType: 'traditional',
            traditionalMarriageDate: '1985-02-01',
            marriagePlace: 'Kpalimé',
          ),
          updatedBy: 'admin',
        );

        expect(updated.marriageRelations, hasLength(1));
        expect(updated.marriageRelations.single.marriageType, 'traditional');
        expect(
          updated.marriageRelations.single.traditionalMarriageDate,
          '1985-02-01',
        );
        expect(updated.people.first.spouseIds, contains('p002'));
        expect(updated.people.last.spouseIds, contains('p001'));
      },
    );

    test(
      'updates an existing union instead of creating an A-B/B-A duplicate',
      () {
        final updated = service.upsertUnion(
          data,
          const MarriageRelation(
            id: '',
            personId: 'p002',
            spouseId: 'p001',
            marriageType: 'civil',
            status: 'separated',
          ),
          updatedBy: 'admin',
        );

        expect(updated.marriageRelations, hasLength(1));
        expect(updated.marriageRelations.single.id, relation.id);
        expect(updated.marriageRelations.single.marriageType, 'civil');
        expect(updated.marriageRelations.single.status, 'separated');
        expect(updated.marriageRelations.single.version, relation.version + 1);
      },
    );

    test('logically deletes a union without deleting members', () {
      final updated = service.deleteUnion(data, relation, deletedBy: 'admin');

      expect(updated.people, hasLength(2));
      expect(updated.marriageRelations.single.deletedAt, isNotEmpty);
      expect(service.relationsFor(updated, ama.id), isEmpty);
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

  test(
    'MarriageRelation serializes traditional union fields and legacy partner ids',
    () {
      final parsed = MarriageRelation.fromJson({
        'id': 'marriage002',
        'familyId': 'ayivon',
        'partner1Id': 'p001',
        'partner2Id': 'p002',
        'marriageType': 'customary',
        'marriageDate': '1985-02-01',
        'marriagePlace': 'Kpalimé',
        'marriageCountry': 'Togo',
      });

      expect(parsed.personId, 'p001');
      expect(parsed.spouseId, 'p002');
      expect(parsed.partner1Id, 'p001');
      expect(parsed.partner2Id, 'p002');
      expect(parsed.marriageType, 'traditional');
      expect(parsed.traditionalMarriageDate, '1985-02-01');
      expect(parsed.marriageCountry, 'Togo');
    },
  );
}
