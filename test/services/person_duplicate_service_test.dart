import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/person_duplicate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects duplicate person with same name and birth date', () {
    const service = PersonDuplicateService();
    const existing = Person(
      id: 'p001',
      firstName: 'Kossi',
      lastName: 'Amouzou',
      birthDate: '1950-01-15',
      birthPlace: 'Kpalime',
    );
    const draft = Person(
      id: 'p999',
      firstName: ' kossi ',
      lastName: 'amouzou',
      birthDate: '1950-01-15',
      birthPlace: 'Kpalime',
    );

    final matches = service.findDuplicates(
      draft: draft,
      people: const [existing],
    );

    expect(matches, hasLength(1));
    expect(matches.first.person.id, 'p001');
    expect(matches.first.reasons, contains('Même nom et prénom'));
    expect(matches.first.reasons, contains('Même date de naissance'));
  });

  test('ignores current edited person and deleted profiles', () {
    const service = PersonDuplicateService();
    const draft = Person(
      id: 'p001',
      firstName: 'Kossi',
      lastName: 'Amouzou',
      birthDate: '1950-01-15',
    );

    final matches = service.findDuplicates(
      draft: draft,
      people: const [
        draft,
        Person(
          id: 'p002',
          firstName: 'Kossi',
          lastName: 'Amouzou',
          birthDate: '1950-01-15',
          deletedAt: '2026-01-01T00:00:00',
        ),
      ],
    );

    expect(matches, isEmpty);
  });
}
