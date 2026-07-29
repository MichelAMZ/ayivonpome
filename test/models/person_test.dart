import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/person.dart';

void main() {
  test('tolerates missing and incorrectly typed legacy fields', () {
    final person = Person.fromJson({
      'id': 'p1',
      'firstName': 42,
      'allowContact': 'yes',
      'generation': 'unknown',
      'spouseIds': [null, 3, 'p2'],
      'privacy': 'legacy',
      'importantPlaces': 'invalid',
    });

    expect(person.id, 'p1');
    expect(person.firstName, '');
    expect(person.allowContact, isTrue);
    expect(person.generation, 0);
    expect(person.spouseIds, ['p2']);
    expect(person.importantPlaces, isEmpty);
  });

  group('Person origin last name', () {
    test('shows birth last name for a female person when different', () {
      const person = Person(
        id: 'p1',
        firstName: 'Ama',
        lastName: 'Amouzou',
        birthLastName: 'Lévonvi',
        gender: 'female',
      );

      expect(person.originLastName, 'Lévonvi');
      expect(person.shouldShowOriginLastName, isTrue);
    });

    test(
      'does not show origin last name when it matches current last name',
      () {
        const person = Person(
          id: 'p1',
          firstName: 'Ama',
          lastName: 'Amouzou',
          birthLastName: 'Amouzou',
          gender: 'female',
        );

        expect(person.shouldShowOriginLastName, isFalse);
      },
    );

    test(
      'does not show birth last name for men unless original name is explicit',
      () {
        const birthOnly = Person(
          id: 'p1',
          firstName: 'Kossi',
          lastName: 'Amouzou',
          birthLastName: 'Ayivon',
          gender: 'male',
        );
        const explicitOriginal = Person(
          id: 'p2',
          firstName: 'Kossi',
          lastName: 'Amouzou',
          originalLastName: 'Ayivon',
          gender: 'male',
        );

        expect(birthOnly.shouldShowOriginLastName, isFalse);
        expect(explicitOriginal.shouldShowOriginLastName, isTrue);
      },
    );

    test('serializes birth and original last names', () {
      const person = Person(
        id: 'p1',
        firstName: 'Ama',
        lastName: 'Amouzou',
        birthLastName: 'Lévonvi',
        originalLastName: 'Lévonvi',
        gender: 'F',
      );

      final decoded = Person.fromJson(person.toJson());

      expect(decoded.birthLastName, 'Lévonvi');
      expect(decoded.originalLastName, 'Lévonvi');
      expect(decoded.shouldShowOriginLastName, isTrue);
    });

    test('serializes linked family tree fields', () {
      const person = Person(
        id: 'p1',
        firstName: 'Ama',
        lastName: 'Amouzou',
        familyId: 'family-ayivon',
        originFamilyId: 'family-levonvi',
        linkedTreeEnabled: true,
      );

      final decoded = Person.fromJson(person.toJson());

      expect(decoded.familyId, 'family-ayivon');
      expect(decoded.originFamilyId, 'family-levonvi');
      expect(decoded.linkedTreeEnabled, isTrue);
    });
  });
}
