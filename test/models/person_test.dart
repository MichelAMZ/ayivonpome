import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/person.dart';

void main() {
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
  });
}
