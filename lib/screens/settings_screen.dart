import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LanguageSelector(value: data.language),
          const SizedBox(height: 16),
          Card(
            child: FutureBuilder<String>(
              future: ref.read(jsonStorageServiceProvider).storageLocation(),
              builder: (context, snapshot) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l10n.storage),
                subtitle: Text(snapshot.data ?? ''),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(l10n.role),
              subtitle: Text(auth.session?.role ?? l10n.readOnly),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
