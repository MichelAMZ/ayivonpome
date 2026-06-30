import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_tree_data.dart';
import 'family_tree_provider.dart';

int getTotalMembers(FamilyTreeData data) => data.people.length;

final membersCountProvider = Provider<int>((ref) {
  final tree = ref.watch(familyTreeProvider);
  return tree.maybeWhen(data: getTotalMembers, orElse: () => 0);
});
