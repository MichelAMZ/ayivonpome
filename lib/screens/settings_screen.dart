import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/bug_report_button.dart';
import '../widgets/responsive.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String value) =>
      _query.isEmpty || value.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final sections = <_SettingsSection>[
      _SettingsSection(
        searchText: '${l10n.language} ${l10n.storage} ${l10n.role} application',
        child: _SettingsSectionCard(
          icon: Icons.tune_rounded,
          title: 'Application',
          description: 'Langue, stockage et niveau d’accès.',
          children: [
            _SettingsContentTile(
              icon: Icons.translate_rounded,
              title: l10n.language,
              child: LanguageSelector(value: data.language),
            ),
            _SettingsDivider(),
            FutureBuilder<String>(
              future: ref.read(jsonStorageServiceProvider).storageLocation(),
              builder: (context, snapshot) => _SettingsInfoTile(
                icon: Icons.folder_outlined,
                title: l10n.storage,
                value: snapshot.data ?? '',
              ),
            ),
            _SettingsDivider(),
            _SettingsInfoTile(
              icon: Icons.verified_user_outlined,
              title: l10n.role,
              value: auth.session?.role ?? l10n.readOnly,
            ),
          ],
        ),
      ),
      if (auth.isAdmin)
        _SettingsSection(
          searchText:
              '${l10n.autoHistoryCleanup} ${l10n.historiesKept} ${l10n.lastCleanup}',
          child: _SettingsSectionCard(
            icon: Icons.history_rounded,
            title: 'Historique des informations',
            description: l10n.historyCleanupNotice,
            children: [
              _SettingsSwitchTile(
                icon: Icons.auto_delete_outlined,
                title: l10n.autoHistoryCleanup,
                description: l10n.historyCleanupNotice,
                value: data.autoCleanupInfoNewsSendHistory,
                onChanged: (value) =>
                    _setHistoryCleanupEnabled(ref, auth, value),
              ),
              _SettingsDivider(),
              _SettingsInfoTile(
                icon: Icons.inventory_2_outlined,
                title: '${l10n.historiesKept}: ${data.infoNewsSendLogs.length}',
                value:
                    '${l10n.lastCleanup}: ${_formatDate(data.infoNewsSendHistoryLastCleanedAt)}',
              ),
              const SizedBox(height: 16),
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
      if (auth.isAdmin)
        _SettingsSection(
          searchText:
              '${l10n.autoCleanupNotifications} ${l10n.autoCleanupKpiActivityLogs} ${l10n.cleanNow}',
          child: _SettingsSectionCard(
            icon: Icons.cleaning_services_rounded,
            title: 'Nettoyage automatique',
            description:
                'Gérez la conservation des notifications et activités.',
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.autoCleanupNotifications,
                value: data.autoCleanupNotifications,
                onChanged: (value) => _setDataCleanupSettings(
                  ref,
                  auth,
                  autoCleanupNotifications: value,
                  autoCleanupKpiActivityLogs: data.autoCleanupKpiActivityLogs,
                ),
              ),
              _SettingsDivider(),
              _SettingsSwitchTile(
                icon: Icons.analytics_outlined,
                title: l10n.autoCleanupKpiActivityLogs,
                value: data.autoCleanupKpiActivityLogs,
                onChanged: (value) => _setDataCleanupSettings(
                  ref,
                  auth,
                  autoCleanupNotifications: data.autoCleanupNotifications,
                  autoCleanupKpiActivityLogs: value,
                ),
              ),
              _SettingsDivider(),
              _SettingsInfoTile(
                icon: Icons.event_available_outlined,
                title:
                    '${l10n.lastCleanup}: ${_formatDate(data.dataCleanupLastCleanedAt)}',
                value:
                    '${l10n.deletedItems}: ${data.dataCleanupLastDeletedCount}',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: () => _confirmAndRunDataCleanup(context, ref),
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text(l10n.cleanNow),
                ),
              ),
            ],
          ),
        ),
      _SettingsSection(
        searchText: '${l10n.reportBug} ${l10n.cancel} session assistance',
        child: _SettingsSectionCard(
          icon: Icons.support_agent_rounded,
          title: 'Assistance et session',
          description: 'Signalez un problème ou fermez la session actuelle.',
          children: [
            const BugReportButton(initialScreen: 'SettingsScreen'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authSessionProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    ].where((section) => _matches(section.searchText)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      body: ResponsivePage(
        maxWidth: 1500,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        children: [
          _SettingsHeader(
            title: l10n.settings,
            controller: _searchController,
            synchronized: data.pendingSyncQueue.isEmpty,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 28),
          _SettingsGrid(sections: sections),
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

class _SettingsSection {
  const _SettingsSection({required this.searchText, required this.child});

  final String searchText;
  final Widget child;
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.title,
    required this.controller,
    required this.synchronized,
    required this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final bool synchronized;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E7E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final identity = Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personnalisez le comportement de votre application familiale.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 16),
                    _SettingsStatusChip(synchronized: synchronized),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 20),
                  _SettingsStatusChip(synchronized: synchronized),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher un paramètre…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7F8F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDDE3DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDDE3DA)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsStatusChip extends StatelessWidget {
  const _SettingsStatusChip({required this.synchronized});

  final bool synchronized;

  @override
  Widget build(BuildContext context) {
    final color = synchronized ? const Color(0xFF2E7D32) : Colors.orange;
    return Semantics(
      label: synchronized
          ? 'Données synchronisées'
          : 'Synchronisation en attente',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              synchronized
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_queue_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 7),
            Text(
              synchronized ? 'Synchronisé' : 'En attente',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({required this.sections});

  final List<_SettingsSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: Text('Aucun paramètre correspondant.')),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 24.0;
        final columns = constraints.maxWidth >= 1320
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final section in sections)
              SizedBox(width: width, child: section.child),
          ],
        );
      },
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE1E6DE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 24, color: Color(0xFFE8ECE6));
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsContentTile extends StatelessWidget {
  const _SettingsContentTile({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
