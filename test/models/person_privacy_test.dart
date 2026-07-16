import 'dart:convert';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/models/person_privacy.dart';
import 'package:ayivonpome/services/import_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('always exposes first name, last name and public map location', () {
    const person = Person(
      id: 'p1',
      firstName: 'Afi',
      lastName: 'Amouzou',
      publicMapLocation: 'Lome, Togo',
      email: 'afi@example.com',
      privacy: PersonPrivacy(emailVisible: false),
    );

    final publicJson = person.toPublicJson();

    expect(publicJson['firstName'], 'Afi');
    expect(publicJson['lastName'], 'Amouzou');
    expect(publicJson['publicMapLocation'], 'Lome, Togo');
    expect(publicJson.containsKey('email'), isFalse);
  });

  test('legacy privacy defaults keep sensitive values hidden', () {
    final privacy = PersonPrivacy.fromJson(const {});

    expect(privacy.showMapInPublicMode, isTrue);
    expect(privacy.emailVisible, isFalse);
    expect(privacy.phoneVisible, isFalse);
    expect(privacy.whatsappVisible, isFalse);
    expect(privacy.privateCoordinatesVisible, isFalse);
    expect(privacy.notesVisible, isFalse);
  });

  test('quick sensitive hide never hides mandatory public fields', () {
    const privacy = PersonPrivacy(
      showMapInPublicMode: false,
      emailVisible: true,
      phoneVisible: true,
      notesVisible: true,
    );

    final hidden = privacy.hideSensitive();

    expect(hidden.showMapInPublicMode, isTrue);
    expect(hidden.emailVisible, isFalse);
    expect(hidden.phoneVisible, isFalse);
    expect(hidden.notesVisible, isFalse);
  });

  test('public export omits hidden sensitive fields', () {
    const data = FamilyTreeData(
      people: [
        Person(
          id: 'p1',
          firstName: 'Afi',
          lastName: 'Amouzou',
          publicMapLocation: 'Lome, Togo',
          email: 'afi@example.com',
          notes: 'private note',
          privacy: PersonPrivacy(emailVisible: false, notesVisible: false),
        ),
      ],
    );

    final exported = ImportExportService().serializePublic(data);
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    final person = (decoded['people'] as List).single as Map<String, dynamic>;

    expect(person['firstName'], 'Afi');
    expect(person['lastName'], 'Amouzou');
    expect(person['publicMapLocation'], 'Lome, Togo');
    expect(person.containsKey('email'), isFalse);
    expect(person.containsKey('notes'), isFalse);
  });
}
