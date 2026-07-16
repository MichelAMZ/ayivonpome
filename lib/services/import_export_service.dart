import 'dart:convert';

import '../models/family_tree_data.dart';
import '../models/person.dart';

class ImportExportService {
  FamilyTreeData parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The JSON root must be an object.');
    }
    return FamilyTreeData.fromJson(decoded);
  }

  String serialize(FamilyTreeData data) =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  String serializePublic(FamilyTreeData data) =>
      const JsonEncoder.withIndent('  ').convert({
        ...data.toJson(),
        'people': data.people.map((person) => person.toPublicJson()).toList(),
      });

  FamilyTreeData merge(FamilyTreeData current, FamilyTreeData imported) {
    final peopleById = {for (final person in current.people) person.id: person};
    for (final importedPerson in imported.people) {
      peopleById.putIfAbsent(importedPerson.id, () => importedPerson);
      final existing = peopleById[importedPerson.id]!;
      if (_isSamePerson(existing, importedPerson)) {
        peopleById[importedPerson.id] = existing.copyWith(
          parents: {...existing.parents, ...importedPerson.parents}.toList(),
          spouses: {...existing.spouses, ...importedPerson.spouses}.toList(),
          children: {...existing.children, ...importedPerson.children}.toList(),
        );
      }
    }
    return current.copyWith(
      people: peopleById.values.toList(),
      familyCodes: {
        for (final family in [...current.familyCodes, ...imported.familyCodes])
          family.code: family,
      }.values.toList(),
      modificationCodes: {
        for (final code in [
          ...current.modificationCodes,
          ...imported.modificationCodes,
        ])
          code.code: code,
      }.values.toList(),
      admins: {
        for (final admin in [...current.admins, ...imported.admins])
          admin.id: admin,
      }.values.toList(),
      familyLinks: {
        for (final link in [...current.familyLinks, ...imported.familyLinks])
          link.id: link,
      }.values.toList(),
      marriageRelations: {
        for (final marriage in [
          ...current.marriageRelations,
          ...imported.marriageRelations,
        ])
          marriage.id: marriage,
      }.values.toList(),
      auditLog: [...current.auditLog, ...imported.auditLog],
    );
  }

  bool _isSamePerson(Person a, Person b) {
    return a.firstName.toLowerCase() == b.firstName.toLowerCase() &&
        a.lastName.toLowerCase() == b.lastName.toLowerCase() &&
        a.birthDate == b.birthDate;
  }
}
