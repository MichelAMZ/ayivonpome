import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_code.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';

class LinkedFamiliesScreen extends ConsumerWidget {
  const LinkedFamiliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkedFamilies)),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showFamilyDialog(context, ref),
              icon: const Icon(Icons.add_link),
              label: Text(l10n.addFamilyCode),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.familyCodes.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.emptyState),
            ))
          else
            ...data.familyCodes.map(
              (family) => Card(
                child: ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(family.familyName),
                  subtitle: Text('${family.code} · ${_label(l10n, family.role)}'),
                  trailing: auth.isAdmin
                      ? SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'pending', label: Text(l10n.pending)),
                            ButtonSegment(value: 'accepted', label: Text(l10n.accepted)),
                            ButtonSegment(value: 'refused', label: Text(l10n.refused)),
                          ],
                          selected: {family.status},
                          onSelectionChanged: (value) => ref
                              .read(familyTreeProvider.notifier)
                              .upsertFamilyCode(
                                family.copyWith(status: value.single),
                              ),
                        )
                      : Chip(label: Text(_label(l10n, family.status))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFamilyDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final code = TextEditingController();
    final name = TextEditingController();
    var role = 'viewer';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addFamilyCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                decoration: InputDecoration(labelText: l10n.familyCode),
              ),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.linkedFamilies),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(labelText: l10n.role),
                items: [
                  DropdownMenuItem(value: 'viewer', child: Text(l10n.viewer)),
                  DropdownMenuItem(value: 'editor', child: Text(l10n.editor)),
                ],
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(familyTreeProvider.notifier).upsertFamilyCode(
                      FamilyCode(
                        code: code.text.trim().toUpperCase(),
                        familyName: name.text.trim(),
                        role: role,
                        status: 'pending',
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

  String _label(AppLocalizations l10n, String value) => switch (value) {
        'owner' => l10n.owner,
        'editor' => l10n.editor,
        'viewer' => l10n.viewer,
        'accepted' => l10n.accepted,
        'refused' => l10n.refused,
        'pending' => l10n.pending,
        _ => value,
      };
}
