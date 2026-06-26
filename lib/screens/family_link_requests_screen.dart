import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_link.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';

class FamilyLinkRequestsScreen extends ConsumerWidget {
  const FamilyLinkRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyLinks)),
      floatingActionButton:
          auth.isAuthenticated && data.people.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _showLinkDialog(context, ref),
              icon: const Icon(Icons.add_link),
              label: Text(l10n.requestFamilyLink),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.familyLinks.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.emptyState),
            ))
          else
            ...data.familyLinks.map(
              (link) => Card(
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    '${_name(link.fromPersonId, ref)} → ${_name(link.toPersonId, ref)}',
                  ),
                  subtitle: Text(
                    '${_relationship(l10n, link.relationshipType)} · ${link.linkedFamilyCode}\n${link.notes}',
                  ),
                  trailing: auth.isAdmin
                      ? Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: l10n.accept,
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => ref
                                  .read(familyTreeProvider.notifier)
                                  .upsertFamilyLink(
                                    link.copyWith(status: 'accepted'),
                                  ),
                            ),
                            IconButton(
                              tooltip: l10n.refuse,
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () => ref
                                  .read(familyTreeProvider.notifier)
                                  .upsertFamilyLink(
                                    link.copyWith(status: 'refused'),
                                  ),
                            ),
                          ],
                        )
                      : Chip(label: Text(_status(l10n, link.status))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final data = ref.read(familyTreeProvider).value!;
    var from = data.people.first.id;
    var to = data.people.skip(1).first.id;
    var type = 'marriage';
    final code = TextEditingController(text: data.familyCodes.firstOrNull?.code ?? '');
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.requestFamilyLink),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _personSelect(l10n.sourcePerson, from, data, (value) {
                  setState(() => from = value ?? from);
                }),
                _personSelect(l10n.targetPerson, to, data, (value) {
                  setState(() => to = value ?? to);
                }),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: l10n.relationshipType),
                  items: [
                    'marriage',
                    'parent',
                    'child',
                    'adoption',
                    'alliance',
                    'commonAncestor',
                    'other',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_relationship(l10n, value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => type = value ?? type),
                ),
                TextField(
                  controller: code,
                  decoration: InputDecoration(labelText: l10n.familyCode),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(familyTreeProvider.notifier).upsertFamilyLink(
                      FamilyLink(
                        id: 'link${DateTime.now().microsecondsSinceEpoch}',
                        fromPersonId: from,
                        toPersonId: to,
                        relationshipType: type,
                        linkedFamilyCode: code.text.trim().toUpperCase(),
                        notes: note.text.trim(),
                      ),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personSelect(
    String label,
    String value,
    dynamic data,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: data.people
          .map<DropdownMenuItem<String>>(
            (person) => DropdownMenuItem(value: person.id, child: Text(person.fullName)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _name(String id, WidgetRef ref) {
    final data = ref.read(familyTreeProvider).value!;
    return data.people
            .where((person) => person.id == id)
            .firstOrNull
            ?.fullName ??
        id;
  }

  String _status(AppLocalizations l10n, String value) => switch (value) {
        'accepted' => l10n.accepted,
        'refused' => l10n.refused,
        _ => l10n.pending,
      };

  String _relationship(AppLocalizations l10n, String value) => switch (value) {
        'marriage' => l10n.marriage,
        'parent' => l10n.parent,
        'child' => l10n.child,
        'adoption' => l10n.adoption,
        'alliance' => l10n.alliance,
        'commonAncestor' => l10n.commonAncestor,
        _ => l10n.other,
      };
}
