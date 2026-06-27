import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/responsive.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ResponsivePage(
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
          if (auth.isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: data.autoCleanupInfoNewsSendHistory,
                      secondary: const Icon(Icons.auto_delete_outlined),
                      title: Text(l10n.autoHistoryCleanup),
                      subtitle: Text(l10n.historyCleanupNotice),
                      onChanged: (value) =>
                          _setHistoryCleanupEnabled(ref, auth, value),
                    ),
                    ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: Text(
                        '${l10n.historiesKept}: ${data.infoNewsSendLogs.length}',
                      ),
                      subtitle: Text(
                        '${l10n.lastCleanup}: ${_formatDate(data.infoNewsSendHistoryLastCleanedAt)}',
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmAndCleanOldHistory(context, ref, auth),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(l10n.deleteOldHistoriesNow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (auth.isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: data.autoCleanupNotifications,
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      title: Text(l10n.autoCleanupNotifications),
                      onChanged: (value) => _setDataCleanupSettings(
                        ref,
                        auth,
                        autoCleanupNotifications: value,
                        autoCleanupKpiActivityLogs:
                            data.autoCleanupKpiActivityLogs,
                      ),
                    ),
                    SwitchListTile(
                      value: data.autoCleanupKpiActivityLogs,
                      secondary: const Icon(Icons.analytics_outlined),
                      title: Text(l10n.autoCleanupKpiActivityLogs),
                      onChanged: (value) => _setDataCleanupSettings(
                        ref,
                        auth,
                        autoCleanupNotifications: data.autoCleanupNotifications,
                        autoCleanupKpiActivityLogs: value,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: Text(
                        '${l10n.lastCleanup}: ${_formatDate(data.dataCleanupLastCleanedAt)}',
                      ),
                      subtitle: Text(
                        '${l10n.deletedItems}: ${data.dataCleanupLastDeletedCount}',
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmAndRunDataCleanup(context, ref),
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: Text(l10n.cleanNow),
                      ),
                    ),
                  ],
                ),
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

  Future<void> _setHistoryCleanupEnabled(
    WidgetRef ref,
    AuthState auth,
    bool enabled,
  ) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateInfoNewsSendHistoryCleanupSetting(
          enabled: enabled,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _confirmAndCleanOldHistory(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteOldHistoriesNow),
        content: Text(l10n.confirmDeleteOldHistories),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteOldHistoriesNow),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(familyTreeProvider.notifier)
        .cleanOldInfoNewsSendHistory(
          force: true,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _setDataCleanupSettings(
    WidgetRef ref,
    AuthState auth, {
    required bool autoCleanupNotifications,
    required bool autoCleanupKpiActivityLogs,
  }) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateDataCleanupSettings(
          autoCleanupNotifications: autoCleanupNotifications,
          autoCleanupKpiActivityLogs: autoCleanupKpiActivityLogs,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _confirmAndRunDataCleanup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cleanNow),
        content: Text(l10n.confirmDataCleanup),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cleanNow),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
