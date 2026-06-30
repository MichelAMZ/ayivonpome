import 'dart:math' as math;

import '../models/location_filter.dart';
import '../models/person.dart';

class LocationFilterService {
  const LocationFilterService();

  List<Person> filterPeopleByLocation(
    List<Person> people,
    LocationFilter filter,
  ) {
    if (!filter.isActive) return people;
    return people.where((person) => matches(person, filter)).toList();
  }

  bool matches(Person person, LocationFilter filter) {
    if (!filter.isActive) return true;
    return _matchesAny(
          filter.country,
          person.currentCountry,
          person.birthCountry,
          person.currentAddress,
          person.birthPlace,
          person.deathPlace,
          person.burialPlace,
          person.publicMapLocation,
        ) &&
        _matchesAny(
          filter.city,
          person.currentCity,
          person.birthCity,
          person.currentAddress,
          person.birthPlace,
          person.publicMapLocation,
        ) &&
        _matchesAny(
          filter.region,
          person.currentRegion,
          person.currentAddress,
        ) &&
        _matchesAny(
          filter.currentAddress,
          person.currentAddress,
          person.publicMapLocation,
        ) &&
        _matchesAny(
          filter.birthLocation,
          person.birthPlace,
          person.birthCity,
        ) &&
        _matchesAny(filter.deathLocation, person.deathPlace) &&
        _matchesAny(filter.burialLocation, person.burialPlace) &&
        _matchesRadiusAddress(filter.radiusAddress, person) &&
        _matchesGeneration(filter.generation, person);
  }

  bool _matchesGeneration(int? generation, Person person) {
    if (generation == null) return true;
    return person.generation == generation;
  }

  bool _matchesAny(
    String query,
    String first, [
    String second = '',
    String third = '',
    String fourth = '',
    String fifth = '',
    String sixth = '',
    String seventh = '',
    String eighth = '',
  ]) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return true;
    return [
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      eighth,
    ].any((value) => _normalize(value).contains(normalizedQuery));
  }

  bool _matchesRadiusAddress(String query, Person person) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return true;
    if (person.latitude == null || person.longitude == null) {
      return _matchesAny(
        query,
        person.currentAddress,
        person.publicMapLocation,
      );
    }
    return _matchesAny(query, person.currentAddress, person.publicMapLocation);
  }

  String _normalize(String value) {
    final lower = value.trim().toLowerCase();
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const plain = 'aaaaaaceeeeiiiinooooouuuuyyoeae';
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final index = accents.indexOf(char);
      buffer.write(index == -1 ? char : plain[index]);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  double distanceKm({
    required double firstLatitude,
    required double firstLongitude,
    required double secondLatitude,
    required double secondLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(secondLatitude - firstLatitude);
    final dLon = _radians(secondLongitude - firstLongitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(firstLatitude)) *
            math.cos(_radians(secondLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
