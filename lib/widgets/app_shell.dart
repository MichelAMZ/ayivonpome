import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/family_link_requests_screen.dart';
import '../screens/linked_families_screen.dart';
import '../screens/modification_history_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tree_screen.dart';
import '../services/admin_access_service.dart';
import 'change_notification_popup.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _index = 0;
  var _popupOpen = false;
  var _adminKpiUnlocked = false;
  final _dismissedThisSession = <String>{};

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authSessionProvider, (previous, next) {
      if (previous?.isAuthenticated != true && next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLatestChangesPopup(next.session?.familyCode ?? '');
        });
      }
      if (!next.isAuthenticated) {
        _dismissedThisSession.clear();
        _adminKpiUnlocked = false;
      }
    });
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final screens = [
      const TreeScreen(),
      const DashboardScreen(),
      if (authenticated) const LinkedFamiliesScreen(),
      if (authenticated) const FamilyLinkRequestsScreen(),
      if (authenticated) const NotificationsScreen(),
      if (authenticated) const ModificationHistoryScreen(),
      if (authenticated) const AdminDashboardScreen(),
      const SettingsScreen(),
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
      if (authenticated)
        const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Historique',
        ),
      if (authenticated)
        NavigationDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: l10n.adminDashboard,
        ),
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
          backgroundColor: const Color(0xFFFBFCF7),
          appBar: AppBar(
            toolbarHeight: 82,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: const Color(0xFFFFFEFA),
            surfaceTintColor: Colors.transparent,
            titleSpacing: 24,
            title: const _BrandTitle(),
            actions: [
              if (authenticated)
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authSessionProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: _accessButtonStyle(context),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _showAccessDialog(context),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: Text(l10n.enterAccessCode),
                  style: _accessButtonStyle(context),
                ),
              const SizedBox(width: 20),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                _DesktopSidebar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => _selectDestination(
                    value,
                    destinations: destinations,
                    authenticated: authenticated,
                  ),
                  destinations: destinations,
                ),
              Expanded(child: screens[_index]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => _selectDestination(
                    value,
                    destinations: destinations,
                    authenticated: authenticated,
                  ),
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

  Future<void> _showLatestChangesPopup(String familyCode) async {
    if (_popupOpen || familyCode.isEmpty) return;
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final service = ref.read(changeNotificationServiceProvider);
    final notifications = service
        .unseenForCode(data, familyCode)
        .where((item) => !_dismissedThisSession.contains(item.id))
        .toList();
    if (notifications.isEmpty) return;

    _popupOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChangeNotificationPopup(
        notifications: notifications,
        onSeen: () async {
          await ref
              .read(familyTreeProvider.notifier)
              .markChangeNotificationsSeen(
                familyCode,
                notifications.map((item) => item.id),
              );
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
        onClose: () {
          _dismissedThisSession.addAll(notifications.map((item) => item.id));
          Navigator.pop(dialogContext);
        },
        onDoNotShowAgain: () async {
          await ref
              .read(familyTreeProvider.notifier)
              .markChangeNotificationsSeen(
                familyCode,
                notifications.map((item) => item.id),
              );
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
        onViewHistory: () {
          _dismissedThisSession.addAll(notifications.map((item) => item.id));
          Navigator.pop(dialogContext);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ModificationHistoryScreen(),
            ),
          );
        },
      ),
    );
    _popupOpen = false;
  }

  Future<void> _selectDestination(
    int value, {
    required List<NavigationDestination> destinations,
    required bool authenticated,
  }) async {
    final destination = destinations[value];
    final isAdminKpi =
        destination.label == AppLocalizations.of(context).adminDashboard;
    if (authenticated && isAdminKpi && !_adminKpiUnlocked) {
      final ok = await _showAdminAccessDialog(context);
      if (!ok) return;
      _adminKpiUnlocked = true;
    }
    setState(() => _index = value);
  }

  Future<bool> _showAdminAccessDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? error;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.enterAdminCode),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.adminAccessCode,
              errorText: error,
            ),
            onSubmitted: (_) {
              final ok = _validateAdminCode(controller.text);
              if (ok) Navigator.pop(context, true);
              if (!ok) setDialogState(() => error = l10n.invalidAdminCode);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final ok = _validateAdminCode(controller.text);
                if (ok) Navigator.pop(context, true);
                if (!ok) setDialogState(() => error = l10n.invalidAdminCode);
              },
              child: Text(l10n.enter),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == true) {
      _showAdminRotationReminderIfNeeded();
    }
    return result == true;
  }

  bool _validateAdminCode(String code) {
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return false;
    return ref.read(adminAccessServiceProvider).validate(data, code);
  }

  void _showAdminRotationReminderIfNeeded() {
    final data = ref.read(familyTreeProvider).value;
    final auth = ref.read(authSessionProvider);
    if (data == null ||
        !auth.isSuperAdmin ||
        !data.adminAccess.requireCodeRotationReminder) {
      return;
    }
    final status = ref.read(adminAccessServiceProvider).rotationStatus(data);
    if (status != AdminCodeRotationStatus.late) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).adminCodeRotationDue),
      ),
    );
  }

  ButtonStyle _accessButtonStyle(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF3DE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.park, color: Color(0xFF4D742B), size: 28),
        ),
        const SizedBox(width: 14),
        Text(
          'FamilyTreeApp',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final visiblePrimary = destinations.length > 2
        ? destinations.sublist(0, destinations.length - 1)
        : destinations;
    final settingsIndex = destinations.length - 1;
    final hasSettings = destinations.isNotEmpty;

    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFA),
        border: Border(right: BorderSide(color: Color(0xFFE3E5DC))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
        child: Column(
          children: [
            for (var i = 0; i < visiblePrimary.length; i++) ...[
              _SidebarItem(
                icon: i == selectedIndex
                    ? visiblePrimary[i].selectedIcon ?? visiblePrimary[i].icon
                    : visiblePrimary[i].icon,
                label: visiblePrimary[i].label,
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            if (hasSettings)
              _SidebarItem(
                icon: selectedIndex == settingsIndex
                    ? destinations[settingsIndex].selectedIcon ??
                          destinations[settingsIndex].icon
                    : destinations[settingsIndex].icon,
                label: destinations[settingsIndex].label,
                selected: selectedIndex == settingsIndex,
                outlined: true,
                onTap: () => onDestinationSelected(settingsIndex),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? const Color(0xFFEAF3D7) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: const Color(0xFFE1E4DA))
                : selected
                ? Border.all(color: const Color(0x00000000))
                : null,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: selected ? primary : const Color(0xFF4C4F46),
              size: 24,
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected ? primary : const Color(0xFF33352F),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
