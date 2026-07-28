import 'package:ayivonpome/data/firestore/firestore_document_mapper.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FirestoreDocumentMapper();
  const sensitiveKeys = {
    'birthDate',
    'currentAddress',
    'email',
    'phone',
    'phoneNumber',
    'whatsapp',
    'whatsappNumber',
    'latitude',
    'longitude',
    'notes',
    'privateNotes',
    'privacy',
    'visibilitySettings',
    'ownerUid',
    'createdBy',
    'updatedBy',
  };

  const person = Person(
    id: 'member_001',
    familyId: 'ayivon',
    firstName: 'Koffi',
    lastName: 'Ayivon',
    gender: 'male',
    birthDate: '1950-04-12',
    birthCity: 'Lomé',
    familyCode: 'AYIVON',
    fatherId: 'father_001',
    spouseIds: ['spouse_001'],
    currentAddress: 'Adresse complète',
    email: 'private@example.test',
    phoneNumber: '+22800000000',
    whatsappNumber: '+22811111111',
    latitude: 6.13,
    longitude: 1.22,
    notes: 'Note strictement privée',
    updatedBy: 'firebase-uid',
  );

  test(
    'la projection publique utilise une liste blanche sans donnée privée',
    () {
      final data = mapper.toMemberPublic(person, familyId: 'ayivon');

      expect(data['id'], 'member_001');
      expect(data['familyId'], 'ayivon');
      expect(data['birthYear'], 1950);
      expect(data['birthCity'], 'Lomé');
      expect(data['familyCode'], 'AYIVON');
      expect(data['schemaVersion'], 2);
      expect(data.keys.toSet().intersection(sensitiveKeys), isEmpty);
    },
  );

  test(
    'la projection privée contient le complément et ne revendique aucun owner',
    () {
      final data = mapper.toMemberPrivate(person, familyId: 'ayivon');

      expect(data['memberId'], 'member_001');
      expect(data['fullBirthDate'], '1950-04-12');
      expect(data['email'], 'private@example.test');
      expect(data['phone'], '+22800000000');
      expect(data['privateNotes'], 'Note strictement privée');
      expect(data.containsKey('ownerUid'), isFalse);
      expect(data.containsKey('firstName'), isFalse);
      expect(data.containsKey('lastName'), isFalse);
    },
  );

  test('ownerUid ne peut être ajouté que par une valeur explicite', () {
    final data = mapper.toMemberPrivate(
      person,
      familyId: 'ayivon',
      ownerUid: 'claimed-owner-uid',
    );

    expect(data['ownerUid'], 'claimed-owner-uid');
  });

  test('le mapper legacy élimine strictement les champs sensibles', () {
    final mapped = mapper.legacyPublicPersonFromData({
      ...person.toJson(),
      'ownerUid': 'legacy-owner',
      'createdBy': 'legacy-admin',
      'accessCode': 'should-never-leak',
    }, documentId: person.id);

    expect(mapped['birthDate'], '1950');
    expect(mapped['firstName'], 'Koffi');
    expect(
      mapped.keys.toSet().intersection(
        sensitiveKeys.difference(const {'birthDate'}),
      ),
      isEmpty,
    );
    expect(mapped.containsKey('accessCode'), isFalse);
  });

  test('la lecture publique ignore les champs privés injectés', () {
    final mapped = mapper.publicPersonFromData({
      'familyId': 'ayivon',
      'firstName': 'Koffi',
      'lastName': 'Ayivon',
      'birthYear': 1950,
      'familyCode': 'AYIVON',
      'email': 'injected@example.test',
      'privateNotes': 'injected',
      'ownerUid': 'injected-owner',
    }, documentId: 'member_001');

    expect(mapped['birthDate'], '1950');
    expect(mapped['familyCode'], 'AYIVON');
    expect(
      mapped.keys.toSet().intersection(
        sensitiveKeys.difference(const {'birthDate'}),
      ),
      isEmpty,
    );
  });

  test(
    'la fiche privée enrichit à la demande sans altérer l’identité publique',
    () {
      final publicPerson = Person.fromJson(
        mapper.publicPersonFromData({
          'familyId': 'ayivon',
          'firstName': 'Koffi',
          'lastName': 'Ayivon',
          'birthYear': 1950,
        }, documentId: 'member_001'),
      );

      final detailed = mapper.enrichWithPrivateData(publicPerson, {
        'memberId': 'member_001',
        'familyId': 'ayivon',
        'fullBirthDate': '1950-04-12',
        'email': 'private@example.test',
        'privateNotes': 'Note privée',
        'firstName': 'Nom injecté',
      });

      expect(detailed.id, 'member_001');
      expect(detailed.firstName, 'Koffi');
      expect(detailed.birthDate, '1950-04-12');
      expect(detailed.email, 'private@example.test');
      expect(detailed.notes, 'Note privée');
    },
  );
}
