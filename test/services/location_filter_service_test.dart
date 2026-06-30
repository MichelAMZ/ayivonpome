import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/location_filter.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/location_filter_service.dart';

void main() {
  test('filters people by location without case or accent sensitivity', () {
    const service = LocationFilterService();
    const people = [
      Person(
        id: 'p001',
        firstName: 'Ama',
        lastName: 'Amouzou',
        currentCity: 'Lomé',
        currentCountry: 'Togo',
      ),
      Person(
        id: 'p002',
        firstName: 'Kossi',
        lastName: 'Ayivon',
        birthPlace: 'Kpalimé, Togo',
      ),
      Person(
        id: 'p003',
        firstName: 'Mawuli',
        lastName: 'Ayivon',
        burialPlace: 'Aného',
      ),
    ];

    expect(
      service
          .filterPeopleByLocation(people, const LocationFilter(city: 'lome'))
          .map((person) => person.id),
      ['p001'],
    );
    expect(
      service
          .filterPeopleByLocation(
            people,
            const LocationFilter(birthLocation: 'KPALIME'),
          )
          .map((person) => person.id),
      ['p002'],
    );
    expect(
      service
          .filterPeopleByLocation(
            people,
            const LocationFilter(burialLocation: 'aneho'),
          )
          .map((person) => person.id),
      ['p003'],
    );
  });
}
