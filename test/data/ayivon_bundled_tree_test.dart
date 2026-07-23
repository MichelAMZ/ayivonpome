import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ayivonpome/models/family_tree_data.dart';

void main() {
  test('bundled AYIVON tree contains the complete validated genealogy', () {
    final raw = File('assets/data/family_tree.json').readAsStringSync();
    final data = FamilyTreeData.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(data.people, hasLength(23));
    expect(data.accessCodes, isEmpty);
    expect(data.modificationCodes, isEmpty);
    expect(data.adminAccess.enabled, isFalse);
    expect(data.adminAccess.currentAdminCode, isEmpty);
    expect(data.superAdminRecovery.enabled, isFalse);
    expect(data.superAdminRecovery.recoveryCode, isEmpty);
    expect(data.pendingSyncQueue, hasLength(23));
    expect(
      data.pendingSyncQueue.map((item) => item.entityId).toSet(),
      data.people.map((person) => person.id).toSet(),
    );
    expect(
      data.pendingSyncQueue.every(
        (item) =>
            item.entityType == 'person' &&
            item.action == 'create' &&
            item.status == 'pending' &&
            item.payload.isEmpty,
      ),
      isTrue,
    );
    expect(data.familyLeadership.currentLeaderPersonId, 'ayivon--ayivon');

    final peopleById = {for (final person in data.people) person.id: person};
    final root = peopleById['ayivon--ayivon'];
    expect(root, isNotNull);
    expect(root!.generation, 1);
    expect(root.children, hasLength(5));

    var relationCount = 0;
    for (final person in data.people) {
      relationCount += person.children.toSet().length;
      for (final childId in person.children) {
        expect(peopleById, contains(childId));
        expect(peopleById[childId]!.parents, contains(person.id));
      }
    }
    expect(relationCount, 22);
    expect(data.people.map((person) => person.generation).toSet(), {1, 2, 3});
  });
}
