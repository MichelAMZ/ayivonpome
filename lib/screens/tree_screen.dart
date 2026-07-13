import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../providers/linked_family_tree_provider.dart';
import '../providers/tree_runtime_provider.dart';
import '../services/linked_family_tree_service.dart';
import '../widgets/family_tree_canvas.dart';
import 'linked_family_tree_screen.dart';
import 'person_detail_screen.dart';

class TreeScreen extends ConsumerWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final resetToken = ref.watch(treeViewResetProvider);
    final linkedTreeService = ref.watch(linkedFamilyTreeServiceProvider(data));
    final visiblePeopleCount = auth.isAuthenticated
        ? data.people.length
        : data.people.where(_isPubliclyVisible).length;
    return FamilyTreeCanvas(
      data: data,
      authMode: auth.mode,
      membersCount: visiblePeopleCount,
      resetToken: resetToken,
      showMembersCounter: data.appSettings.treeSettings.showMembersCounter,
      topReservedSpace: 8,
      onOpenPerson: (person) => _openPerson(context, linkedTreeService, person),
    );
  }

  bool _isPubliclyVisible(Person person) {
    return '${person.firstName}${person.lastName}'.trim().isNotEmpty;
  }

  Future<void> _openPerson(
    BuildContext context,
    LinkedFamilyTreeService service,
    Person person,
  ) async {
    if (!service.hasLinkedFamilyTree(person)) {
      _openProfile(context, person);
      return;
    }

    final familyId = service.getLinkedFamilyId(person);
    if (familyId == null) {
      _openProfile(context, person);
      return;
    }

    final familyName = service.linkedFamilyName(person);
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_LinkedTreeAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text('Voir la fiche de ${person.fullName}'),
                onTap: () => Navigator.pop(context, _LinkedTreeAction.profile),
              ),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text('${l10n.openFamilyBranch} - $familyName'),
                subtitle: person.originLastName.isEmpty
                    ? null
                    : Text('${person.fullName}, née ${person.originLastName}'),
                onTap: () =>
                    Navigator.pop(context, _LinkedTreeAction.linkedTree),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _LinkedTreeAction.profile:
        _openProfile(context, person);
      case _LinkedTreeAction.linkedTree:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LinkedFamilyTreeScreen(
              focusPersonId: person.id,
              familyId: familyId,
            ),
          ),
        );
    }
  }

  void _openProfile(BuildContext context, Person person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(personId: person.id),
      ),
    );
  }
}

enum _LinkedTreeAction { profile, linkedTree }
