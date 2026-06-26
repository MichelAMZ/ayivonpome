import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/family_link_requests_screen.dart';
import '../screens/linked_families_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tree_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final screens = [
      const TreeScreen(),
      const DashboardScreen(),
      if (authenticated) const LinkedFamiliesScreen(),
      if (authenticated) const FamilyLinkRequestsScreen(),
      if (authenticated) const NotificationsScreen(),
      if (auth.isSuperAdmin) const AdminDashboardScreen(),
      if (authenticated) const SettingsScreen(),
    ];
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.account_tree_outlined),
        selectedIcon: const Icon(Icons.account_tree),
        label: l10n.familyTree,
      ),
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.dashboardTitle,
      ),
      if (authenticated)
        NavigationDestination(
          icon: const Icon(Icons.groups_outlined),
          selectedIcon: const Icon(Icons.groups),
          label: l10n.linkedFamilies,
        ),
      if (authenticated)
        NavigationDestination(
          icon: const Icon(Icons.link_outlined),
          selectedIcon: const Icon(Icons.link),
          label: l10n.familyLinks,
        ),
      if (authenticated)
        NavigationDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications),
          label: l10n.notifications,
        ),
      if (auth.isSuperAdmin)
        NavigationDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: l10n.adminDashboard,
        ),
      if (authenticated)
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
    ];
    if (_index >= screens.length) {
      _index = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text('FamilyTreeApp'),
            actions: [
              if (authenticated)
                TextButton.icon(
                  onPressed: () => ref.read(authSessionProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                )
              else
                FilledButton.icon(
                  onPressed: () => _showAccessDialog(context),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: Text(l10n.enterAccessCode),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (value) => setState(() => _index = value),
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(child: screens[_index]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => setState(() => _index = value),
                  destinations: destinations,
                ),
        );
      },
    );
  }

  Future<void> _showAccessDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.enterAccessCode),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.familyCode,
              errorText: error,
            ),
            onSubmitted: (_) async {
              final ok = await ref
                  .read(authSessionProvider.notifier)
                  .login(controller.text);
              if (context.mounted && ok) Navigator.pop(context);
              if (!ok) setDialogState(() => error = l10n.invalidCode);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await ref
                    .read(authSessionProvider.notifier)
                    .login(controller.text);
                if (context.mounted && ok) Navigator.pop(context);
                if (!ok) setDialogState(() => error = l10n.invalidCode);
              },
              child: Text(l10n.enter),
            ),
          ],
        ),
      ),
    );
  }
}
