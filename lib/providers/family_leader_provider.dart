import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_leadership.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';
import 'family_tree_provider.dart';

final familyLeadershipProvider = Provider<FamilyLeadership>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  return data?.familyLeadership ?? const FamilyLeadership();
});

final familyLeaderProvider = Provider<Person?>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  if (data == null) return null;
  return resolveFamilyLeader(data);
});

Person? resolveFamilyLeader(FamilyTreeData data) {
  final leaderId = data.familyLeadership.currentLeaderPersonId;
  if (leaderId.isEmpty) return null;
  for (final person in data.people) {
    if (person.id == leaderId && person.deletedAt.isEmpty) return person;
  }

  final patriarchId = data.familyHonor.patriarchPersonId;
  if (patriarchId.isNotEmpty) {
    for (final person in data.people) {
      if (person.id == patriarchId && person.deletedAt.isEmpty) return person;
    }
  }

  final roots = data.people
      .where(
        (person) =>
            person.deletedAt.isEmpty &&
            person.fatherId.isEmpty &&
            person.motherId.isEmpty &&
            person.parents.isEmpty,
      )
      .toList(growable: false);
  if (roots.isEmpty) return null;
  roots.sort((left, right) {
    final generationComparison = left.generation.compareTo(right.generation);
    if (generationComparison != 0) return generationComparison;
    return left.id.compareTo(right.id);
  });
  return roots.first;
}
