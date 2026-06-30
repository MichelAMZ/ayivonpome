import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/family_tree_canvas.dart';
import 'person_detail_screen.dart';

class TreeScreen extends ConsumerWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final visiblePeopleCount = auth.isAuthenticated
        ? data.people.length
        : data.people.where(_isPubliclyVisible).length;
    return FamilyTreeCanvas(
      data: data,
      authMode: auth.mode,
      membersCount: visiblePeopleCount,
      showMembersCounter: data.appSettings.treeSettings.showMembersCounter,
      topReservedSpace: 8,
      onOpenPerson: (person) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonDetailScreen(personId: person.id),
        ),
      ),
    );
  }

  bool _isPubliclyVisible(Person person) {
    return '${person.firstName}${person.lastName}'.trim().isNotEmpty;
  }
}
