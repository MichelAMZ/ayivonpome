import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/modification_code_required_dialog.dart';
import 'person_detail_screen.dart';
import 'person_edit_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final pending = data.familyLinks.where((link) => link.status == 'pending').length;
    final filtered = data.people.where((person) {
      final haystack =
          '${person.firstName} ${person.lastName} ${person.birthPlace} ${person.familyCode}'
              .toLowerCase();
      return haystack.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      floatingActionButton: authenticated
          ? FloatingActionButton.extended(
              onPressed: () => _requestModificationThen(() => _openEditor(null)),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addPerson),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(label: l10n.totalPeople, value: '${data.people.length}'),
              if (authenticated)
                _Metric(
                  label: l10n.familiesCount,
                  value: '${data.familyCodes.length}',
                ),
              if (authenticated) _Metric(label: l10n.pendingCount, value: '$pending'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (authenticated) ...[
                FilledButton.icon(
                  onPressed: () => _requestModificationThen(() => _openEditor(null)),
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.addPerson),
                ),
                OutlinedButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.importJson),
                ),
                OutlinedButton.icon(
                  onPressed: _exportJson,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.exportJson),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noResults),
            ))
          else
            ...filtered.map(
              (person) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(person.fullName),
                  subtitle: authenticated
                      ? Text(person.familyCode)
                      : person.privacy.showMapInPublicMode &&
                              person.publicMapLocation.isNotEmpty
                          ? Text(person.publicMapLocation)
                          : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PersonDetailScreen(personId: person.id),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openEditor(Person? person) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonEditScreen(person: person)),
    );
  }

  Future<void> _requestModificationThen(VoidCallback action) async {
    final auth = ref.read(authSessionProvider);
    if (auth.canModify) {
      action();
      return;
    }
    await ref.read(familyTreeProvider.notifier).addAuditLog(
          'modification_code_required',
          actorRole: auth.session?.role ?? 'viewer',
          description:
              'L’utilisateur a cliqué sur Ajouter une personne sans code de modification.',
        );
    if (!mounted) return;
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const ModificationCodeRequiredDialog(),
    );
    if (unlocked == true && mounted) {
      action();
    }
  }

  Future<void> _importJson() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) {
      return;
    }
    try {
      final raw = String.fromCharCodes(bytes);
      final imported = ref.read(importExportServiceProvider).parse(raw);
      if (!mounted) {
        return;
      }
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmOverwrite),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.merge),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.replace),
            ),
          ],
        ),
      );
      if (merge == null) {
        return;
      }
      await ref.read(familyTreeProvider.notifier).importData(imported, merge: merge);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupCreated)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.importError}: $error')),
        );
      }
    }
  }

  Future<void> _exportJson() async {
    final l10n = AppLocalizations.of(context);
    final data = ref.read(familyTreeProvider).value!;
    final raw = ref.read(importExportServiceProvider).serialize(data);
    await FilePicker.platform.saveFile(
      dialogTitle: l10n.exportJson,
      fileName: 'family_tree.json',
      bytes: Uint8List.fromList(raw.codeUnits),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
