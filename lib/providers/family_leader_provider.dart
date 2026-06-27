import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_leadership.dart';
import '../models/person.dart';
import 'family_tree_provider.dart';

final familyLeadershipProvider = Provider<FamilyLeadership>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  return data?.familyLeadership ?? const FamilyLeadership();
});

final familyLeaderProvider = Provider<Person?>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  if (data == null) return null;
  final leaderId = data.familyLeadership.currentLeaderPersonId;
  if (leaderId.isEmpty) return null;
  for (final person in data.people) {
    if (person.id == leaderId) return person;
  }
  return null;
});
