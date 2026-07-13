import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../models/family_tree_data.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../providers/linked_family_tree_provider.dart';
import '../widgets/family_tree_canvas.dart';
import 'person_detail_screen.dart';

class LinkedFamilyTreeScreen extends ConsumerWidget {
  const LinkedFamilyTreeScreen({
    super.key,
    required this.focusPersonId,
    required this.familyId,
  });

  final String focusPersonId;
  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value;
    final auth = ref.watch(authSessionProvider);
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final service = ref.watch(linkedFamilyTreeServiceProvider(data));
    final focusPerson = data.people
        .where((person) => person.id == focusPersonId)
        .firstOrNull;
    if (focusPerson == null) {
      return const Scaffold(body: Center(child: Text('Personne introuvable.')));
    }

    final linkedData = service.buildLinkedFamilyTree(
      familyId: familyId,
      focusPersonId: focusPersonId,
    );
    final familyName = service.linkedFamilyName(focusPerson);
    final mainFamilyName = _mainFamilyName(data);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              familyName.toLowerCase().startsWith('famille ')
                  ? 'Arbre de la $familyName'
                  : 'Arbre de la famille $familyName',
            ),
            Text(
              'Branche familiale de ${focusPerson.fullName}${focusPerson.originLastName.isEmpty ? '' : ', née ${focusPerson.originLastName}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _LinkedTreeHeader(
            mainFamilyName: mainFamilyName,
            bridgePerson: focusPerson,
            linkedFamilyName: familyName,
            backLabel: '${l10n.backToMainTree} - $mainFamilyName',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: FamilyTreeCanvas(
              data: linkedData,
              authMode: auth.mode,
              membersCount: linkedData.people.length,
              showMembersCounter:
                  data.appSettings.treeSettings.showMembersCounter &&
                  data.appSettings.branding.memberCountDisplayMode ==
                      'bottomBar',
              highlightedPersonIds: {focusPersonId},
              onOpenPerson: (person) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PersonDetailScreen(personId: person.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mainFamilyName(FamilyTreeData data) {
    final configured = data.mainFamilyCode.trim().toLowerCase();
    final matches = data.families.where(
      (family) =>
          family.id.trim().toLowerCase() == configured ||
          family.code.trim().toLowerCase() == configured,
    );
    final primary = matches.isEmpty
        ? (data.families.isEmpty ? null : data.families.first)
        : matches.first;
    if (primary != null && primary.name.trim().isNotEmpty) return primary.name;
    return 'Famille ${data.mainFamilyCode.toString().toUpperCase()}';
  }
}

class _LinkedTreeHeader extends StatelessWidget {
  const _LinkedTreeHeader({
    required this.mainFamilyName,
    required this.bridgePerson,
    required this.linkedFamilyName,
    required this.backLabel,
    required this.onBack,
  });

  final String mainFamilyName;
  final Person bridgePerson;
  final String linkedFamilyName;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFA),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(backLabel),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(mainFamilyName),
                  const Icon(Icons.chevron_right, size: 18),
                  Text(bridgePerson.fullName),
                  const Icon(Icons.chevron_right, size: 18),
                  Text(
                    linkedFamilyName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
