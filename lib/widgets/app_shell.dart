import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';
import '../providers/app_settings_provider.dart';
import '../providers/family_leader_provider.dart';
import '../providers/family_tree_provider.dart';
import '../providers/members_count_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/family_honor_hall_screen.dart';
import '../screens/family_council_screen.dart';
import '../screens/family_history_screen.dart';
import '../screens/family_link_requests_screen.dart';
import '../screens/linked_families_screen.dart';
import '../screens/modification_history_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/person_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tree_screen.dart';
import '../services/admin_access_service.dart';
import 'change_notification_popup.dart';
import 'bug_report_button.dart';
import 'family_announcement_popup.dart';
import 'family_council_button.dart';
import 'family_history_button.dart';
import 'family_leader_premium_badge.dart';
import 'info_news_bar.dart';
import 'language_selector_button.dart';
import 'mobile_title_member_count_badge.dart';
import 'responsive.dart';
import 'secure_code_text_field.dart';
import 'sync_status_badge.dart';
import 'topbar_family_logo.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _index = 0;
  var _popupOpen = false;
  var _adminKpiUnlocked = false;
  var _familyAnnouncementsBootstrapped = false;
  var _syncAttemptedThisSession = false;
  final _dismissedThisSession = <String>{};
  final _shownAnnouncementIds = <String>{};

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
    ref.listen(familyTreeProvider, (previous, next) {
      next.whenData((data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!_syncAttemptedThisSession &&
              data.pendingSyncQueue.isNotEmpty &&
              data.syncSettings.syncStatus != 'error') {
            _syncAttemptedThisSession = true;
            ref.read(familyTreeProvider.notifier).syncPendingChanges();
          }
          if (!_familyAnnouncementsBootstrapped) {
            _bootstrapFamilyAnnouncements();
          } else {
            _showFamilyAnnouncementPopup();
          }
        });
      });
    });
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final screens = [
      const TreeScreen(),
      const FamilyHonorHallScreen(),
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
        icon: const Icon(Icons.workspace_premium_outlined),
        selectedIcon: const Icon(Icons.workspace_premium),
        label: l10n.familyHonorHall,
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
        final device = ResponsiveBreakpoints.deviceForWidth(
          constraints.maxWidth,
        );
        final mobileIndices = _mobileDestinationIndices(
          authenticated: authenticated,
          destinationCount: destinations.length,
        );
        final mobileSelectedIndex = mobileIndices.indexOf(_index);
        return ResponsiveScaffold(
          backgroundColor: const Color(0xFFFBFCF7),
          appBar: AppBar(
            toolbarHeight: device == ResponsiveDevice.desktop
                ? 150
                : device == ResponsiveDevice.tablet
                ? 128
                : 96,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: const Color(0xFFFFFEFA),
            surfaceTintColor: Colors.transparent,
            titleSpacing: device == ResponsiveDevice.mobile ? 0 : 24,
            title: const _BrandTitle(),
            actions: _topBarActions(context, device, auth, l10n, destinations),
          ),
          drawer: _NavigationDrawer(
            selectedIndex: _index,
            destinations: destinations,
            onDestinationSelected: (value) {
              Navigator.pop(context);
              _selectDestination(
                value,
                destinations: destinations,
                authenticated: authenticated,
              );
            },
          ),
          desktopNavigation: _DesktopSidebar(
            selectedIndex: _index,
            onDestinationSelected: (value) => _selectDestination(
              value,
              destinations: destinations,
              authenticated: authenticated,
            ),
            destinations: destinations,
          ),
          body: Column(
            children: [
              const InfoNewsBar(),
              const SyncStatusBadge(),
              const _OptionalFamilyLeadershipBanner(),
              Expanded(child: screens[_index]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: mobileSelectedIndex == -1 ? 0 : mobileSelectedIndex,
            onDestinationSelected: (value) => _selectDestination(
              mobileIndices[value],
              destinations: destinations,
              authenticated: authenticated,
            ),
            destinations: [
              for (final index in mobileIndices) destinations[index],
            ],
          ),
        );
      },
    );
  }

  List<int> _mobileDestinationIndices({
    required bool authenticated,
    required int destinationCount,
  }) {
    final last = destinationCount - 1;
    if (!authenticated) return [0, 2, last].where((i) => i <= last).toList();
    return [0, 2, 5, last].where((i) => i <= last).toList();
  }

  List<Widget> _topBarActions(
    BuildContext context,
    ResponsiveDevice device,
    AuthState auth,
    AppLocalizations l10n,
    List<NavigationDestination> destinations,
  ) {
    final authenticated = auth.isAuthenticated;
    final compact = device != ResponsiveDevice.desktop;
    final authAction = authenticated
        ? () => ref.read(authSessionProvider.notifier).logout()
        : () => _showAccessDialog(context);
    if (compact) {
      return [
        const LanguageSelectorButton(compact: true),
        IconButton(
          tooltip: authenticated ? l10n.logout : l10n.enterAccessCode,
          onPressed: authAction,
          icon: Icon(authenticated ? Icons.logout : Icons.lock_open_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'history') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FamilyHistoryScreen()),
              );
            }
            if (value == 'council' && authenticated) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FamilyCouncilScreen()),
              );
            }
            if (value == 'bug' && authenticated) {
              showBugReportDialog(
                context,
                ref,
                initialScreen: _currentScreenName(),
              );
            }
            if (value == 'settings') {
              _selectDestination(
                destinations.length - 1,
                destinations: destinations,
                authenticated: authenticated,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined),
                  const SizedBox(width: 12),
                  Text(l10n.ourHistory),
                ],
              ),
            ),
            if (authenticated)
              PopupMenuItem(
                value: 'bug',
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.reportBug),
                  ],
                ),
              ),
            if (authenticated)
              PopupMenuItem(
                value: 'council',
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined),
                    const SizedBox(width: 12),
                    Text(l10n.familyCouncil),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined),
                  const SizedBox(width: 10),
                  Text(l10n.settings),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ];
    }
    return [
      const LanguageSelectorButton(),
      const SizedBox(width: 10),
      if (authenticated) ...[
        BugReportButton(initialScreen: _currentScreenName()),
        const SizedBox(width: 10),
      ],
      FamilyHistoryButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FamilyHistoryScreen())),
      ),
      const SizedBox(width: 10),
      if (authenticated) ...[
        FamilyCouncilButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FamilyCouncilScreen()),
          ),
        ),
        const SizedBox(width: 10),
      ],
      if (authenticated)
        OutlinedButton.icon(
          onPressed: authAction,
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
          style: _accessButtonStyle(context),
        )
      else
        OutlinedButton.icon(
          onPressed: authAction,
          icon: const Icon(Icons.lock_open_outlined),
          label: Text(l10n.enterAccessCode),
          style: _accessButtonStyle(context),
        ),
      const SizedBox(width: 20),
    ];
  }

  String _currentScreenName() {
    return switch (_index) {
      0 => 'TreeScreen',
      1 => 'FamilyHonorHallScreen',
      2 => 'DashboardScreen',
      _ => 'AppShell',
    };
  }

  Future<void> _showAccessDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AccessEntryDialog(
        title: l10n.enterAccessCode,
        label: l10n.familyCode,
        invalidMessage: l10n.invalidCode,
        cancelLabel: l10n.cancel,
        submitLabel: l10n.enter,
        onValidate: (code) =>
            ref.read(authSessionProvider.notifier).login(code),
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

  Future<void> _bootstrapFamilyAnnouncements() async {
    if (_familyAnnouncementsBootstrapped) return;
    _familyAnnouncementsBootstrapped = true;
    await ref
        .read(familyTreeProvider.notifier)
        .ensureTodayFamilyAnnouncements();
    if (mounted) await _showFamilyAnnouncementPopup();
  }

  Future<void> _showFamilyAnnouncementPopup() async {
    if (_popupOpen) return;
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final service = ref.read(familyAnnouncementServiceProvider);
    final announcements = service
        .pendingPopups(data)
        .where((item) => !_shownAnnouncementIds.contains(item.id))
        .toList();
    if (announcements.isEmpty) return;
    _popupOpen = true;
    _shownAnnouncementIds.addAll(announcements.map((item) => item.id));
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          FamilyAnnouncementPopup(announcements: announcements, data: data),
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
      if (!mounted) return;
      _adminKpiUnlocked = true;
      debugPrint('Navigating to AdminDashboardScreen');
    }
    setState(() => _index = value);
  }

  Future<bool> _showAdminAccessDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    debugPrint('Admin dialog opened');
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CodeEntryDialog(
        title: l10n.enterAdminCode,
        label: l10n.adminAccessCode,
        invalidMessage: l10n.invalidAdminCode,
        cancelLabel: l10n.cancel,
        submitLabel: l10n.enter,
        forgotCodeLabel: l10n.forgotCode,
        onForgotCode: () => _showSuperAdminRecoveryDialog(dialogContext),
        debugAdminFlow: true,
        onValidate: (code) async => _validateAdminCode(code),
      ),
    );
    if (result == true) {
      debugPrint('Opening AdminDashboardScreen');
      _showAdminRotationReminderIfNeeded();
    }
    return result == true;
  }

  Future<void> _showSuperAdminRecoveryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(familyTreeProvider.notifier)
        .addAuditLog(
          'super_admin_recovery_opened',
          actorRole: 'superAdminRecovery',
        );
    if (!context.mounted) return;
    final recoveryCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuperAdminRecoveryCodeDialog(
        onValidate: (code) async {
          final data = ref.read(familyTreeProvider).value;
          if (data == null) return false;
          final ok = ref
              .read(superAdminRecoveryServiceProvider)
              .validate(data, code);
          await ref
              .read(familyTreeProvider.notifier)
              .addAuditLog(
                ok
                    ? 'super_admin_recovery_success'
                    : 'super_admin_recovery_failed',
                actorRole: 'superAdminRecovery',
              );
          return ok;
        },
      ),
    );
    if (recoveryCode == null || !context.mounted) return;
    final didReset = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuperAdminResetCodesDialog(
        recoveryCode: recoveryCode,
        onReset:
            ({
              required recoveryCode,
              required familyAccessCode,
              required adminKpiCode,
              required modificationCode,
              required generateAll,
            }) async {
              return ref
                  .read(familyTreeProvider.notifier)
                  .resetCodesWithSuperAdminRecovery(
                    recoveryCode: recoveryCode,
                    familyAccessCode: familyAccessCode,
                    adminKpiCode: adminKpiCode,
                    modificationCode: modificationCode,
                    generateAll: generateAll,
                  );
            },
      ),
    );
    if (didReset != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.codesResetSuccess)));
  }

  bool _validateAdminCode(String code) {
    debugPrint('Admin code entered');
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return false;
    final valid = ref.read(adminAccessServiceProvider).validate(data, code);
    if (valid) debugPrint('Admin code valid');
    return valid;
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

class _BrandTitle extends ConsumerWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leader = ref.watch(familyLeaderProvider);
    final leadership = ref.watch(familyLeadershipProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final title = appSettings.applicationTitle.trim().isEmpty
        ? AppLocalizations.of(context).appTitle
        : appSettings.applicationTitle.trim();
    final subtitle = appSettings.applicationSubtitle.trim();
    final branding = appSettings.branding;
    final membersCount = ref.watch(membersCountProvider);
    final l10n = AppLocalizations.of(context);
    final showSubtitle =
        appSettings.showApplicationSubtitle && subtitle.isNotEmpty;
    final showLeader =
        leadership.showLeaderInTopBar &&
        leadership.showLeaderBadge &&
        leader != null;
    final showLeaderBadge =
        showLeader && leadership.topBarLogoMode != 'classicLogo';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobile = screenWidth <= ResponsiveBreakpoints.mobileMax;
    final compact = screenWidth <= ResponsiveBreakpoints.tabletMax;
    final desktop = !compact;
    final leaderBadge = showLeaderBadge
        ? FamilyLeaderPremiumBadge(
            person: leader,
            title: leadership.title,
            subtitle: leadership.subtitle,
            photo: leadership.officialPhoto,
            compact: compact,
            onTap: () => _openLeaderProfile(context, leader.id),
            onMenuAction: (action) =>
                _handleLeaderMenuAction(context, ref, leader, action),
          )
        : null;
    final showMobileTitleCounter =
        mobile && appSettings.treeSettings.showMembersCounter;
    final showTitleCounter =
        !showMobileTitleCounter &&
        appSettings.treeSettings.showMembersCounter &&
        branding.memberCountDisplayMode == 'superscriptTitle';
    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF233A2A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  fontSize: desktop
                      ? 34
                      : mobile
                      ? 16
                      : 24,
                ),
              ),
            ),
            if (showTitleCounter) ...[
              const SizedBox(width: 6),
              Transform.translate(
                offset: Offset(0, mobile ? -5 : -10),
                child: Text(
                  membersCount.toString(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF5E6F1F),
                    fontWeight: FontWeight.w900,
                    fontSize: mobile ? 10 : 13,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
            if (showMobileTitleCounter) ...[
              const SizedBox(width: 6),
              MobileTitleMemberCountBadge(count: membersCount),
            ],
          ],
        ),
        if (appSettings.treeSettings.showMembersCounter &&
            branding.memberCountDisplayMode == 'bottomBar')
          Text(
            l10n.membersCount(membersCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5E6F58),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              fontSize: mobile ? 11 : null,
            ),
          ),
        if (showSubtitle && !mobile)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
      ],
    );

    if (!desktop) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (branding.logoPosition == 'leftOfTitle') ...[
            TopbarFamilyLogo(
              membersCount: membersCount,
              settings: branding,
              showCounter: appSettings.treeSettings.showMembersCounter,
            ),
            SizedBox(width: mobile ? 8 : 14),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                if (leaderBadge != null) ...[
                  SizedBox(height: mobile ? 4 : 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: leaderBadge,
                  ),
                ],
              ],
            ),
          ),
          if (branding.logoPosition == 'rightOfTitle') ...[
            SizedBox(width: mobile ? 8 : 14),
            TopbarFamilyLogo(
              membersCount: membersCount,
              settings: branding,
              showCounter: appSettings.treeSettings.showMembersCounter,
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (branding.logoPosition == 'leftOfTitle') ...[
          TopbarFamilyLogo(
            membersCount: membersCount,
            settings: branding,
            showCounter: appSettings.treeSettings.showMembersCounter,
          ),
          const SizedBox(width: 18),
        ],
        Expanded(flex: 4, child: titleBlock),
        if (branding.logoPosition == 'rightOfTitle') ...[
          const SizedBox(width: 18),
          TopbarFamilyLogo(
            membersCount: membersCount,
            settings: branding,
            showCounter: appSettings.treeSettings.showMembersCounter,
          ),
        ],
        if (leaderBadge != null)
          Expanded(
            flex: 5,
            child: Align(alignment: Alignment.center, child: leaderBadge),
          ),
      ],
    );
  }

  void _openLeaderProfile(BuildContext context, String personId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
    );
  }

  Future<void> _handleLeaderMenuAction(
    BuildContext context,
    WidgetRef ref,
    Person leader,
    FamilyLeaderMenuAction action,
  ) async {
    switch (action) {
      case FamilyLeaderMenuAction.profile:
        _openLeaderProfile(context, leader.id);
        return;
      case FamilyLeaderMenuAction.descendants:
      case FamilyLeaderMenuAction.ancestors:
        _openLeaderProfile(context, leader.id);
        return;
      case FamilyLeaderMenuAction.map:
        final publicLocation = leader.publicMapLocation.trim();
        final address = publicLocation.isNotEmpty
            ? publicLocation
            : leader.currentAddress.trim().isNotEmpty
            ? leader.currentAddress
            : leader.birthPlace;
        if (address.trim().isEmpty &&
            (leader.latitude == null || leader.longitude == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun lieu disponible.')),
          );
          return;
        }
        await ref
            .read(mapServiceProvider)
            .openInGoogleMaps(
              address: address,
              latitude: leader.latitude,
              longitude: leader.longitude,
            );
    }
  }
}

class _AccessEntryDialog extends ConsumerStatefulWidget {
  const _AccessEntryDialog({
    required this.title,
    required this.label,
    required this.invalidMessage,
    required this.cancelLabel,
    required this.submitLabel,
    required this.onValidate,
  });

  final String title;
  final String label;
  final String invalidMessage;
  final String cancelLabel;
  final String submitLabel;
  final Future<bool> Function(String code) onValidate;

  @override
  ConsumerState<_AccessEntryDialog> createState() => _AccessEntryDialogState();
}

class _AccessEntryDialogState extends ConsumerState<_AccessEntryDialog> {
  final _codeController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _codeError;
  String? _adminError;
  String? _adminMessage;
  var _submittingCode = false;
  var _submittingAdmin = false;
  var _hasCodeInput = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_syncCodeInputState);
  }

  @override
  void dispose() {
    _codeController.removeListener(_syncCodeInputState);
    _codeController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _syncCodeInputState() {
    final hasInput = _codeController.text.trim().isNotEmpty;
    if (hasInput == _hasCodeInput) return;
    setState(() {
      _hasCodeInput = hasInput;
      if (hasInput) _codeError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecureCodeTextField(
              controller: _codeController,
              label: widget.label,
              autofocus: true,
              enabled: !_submittingCode && !_submittingAdmin,
              errorText: _codeError,
              onSubmitted: (_) {
                if (_hasCodeInput) _submitCode();
              },
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Connexion administrateur Firebase'),
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _adminEmailController,
                  enabled: !_submittingCode && !_submittingAdmin,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email administrateur',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _adminPasswordController,
                  enabled: !_submittingCode && !_submittingAdmin,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: _adminError,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _submitFirebaseAdmin(),
                ),
                if (_adminMessage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _adminMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submittingCode || _submittingAdmin
                            ? null
                            : _sendFirebasePasswordReset,
                        icon: const Icon(Icons.mark_email_read_outlined),
                        label: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submittingCode || _submittingAdmin
                            ? null
                            : _submitFirebaseAdmin,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Se connecter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submittingCode || _submittingAdmin
              ? null
              : () => Navigator.pop(context, false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submittingCode || _submittingAdmin || !_hasCodeInput
              ? null
              : _submitCode,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _submitCode() async {
    if (_submittingCode || !_hasCodeInput) return;
    setState(() {
      _submittingCode = true;
      _codeError = null;
    });
    try {
      final ok = await widget.onValidate(_codeController.text);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _submittingCode = false;
        _codeError = widget.invalidMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingCode = false;
        _codeError = widget.invalidMessage;
      });
    }
  }

  Future<void> _submitFirebaseAdmin() async {
    final email = _adminEmailController.text.trim();
    final password = _adminPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _adminError = 'Email et mot de passe requis.';
        _adminMessage = null;
      });
      return;
    }
    setState(() {
      _submittingAdmin = true;
      _adminError = null;
      _adminMessage = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .loginFirebaseAdmin(email: email, password: password);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submittingAdmin = false;
        _adminError = _friendlyFirebaseError(error);
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _sendFirebasePasswordReset() async {
    final email = _adminEmailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _adminError = 'Email administrateur requis.';
        _adminMessage = null;
      });
      return;
    }
    setState(() {
      _submittingAdmin = true;
      _adminError = null;
      _adminMessage = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .sendFirebasePasswordReset(email);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submittingAdmin = false;
        _adminError = _friendlyFirebaseError(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _submittingAdmin = false;
      _adminMessage = 'Email de réinitialisation envoyé.';
    });
  }

  String _friendlyFirebaseError(Object error) {
    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Identifiants administrateur invalides.';
    }
    if (message.contains('permission-denied')) {
      return 'Rôle Firestore inaccessible pour ce compte.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}

class _CodeEntryDialog extends StatefulWidget {
  const _CodeEntryDialog({
    required this.title,
    required this.label,
    required this.invalidMessage,
    required this.cancelLabel,
    required this.submitLabel,
    required this.onValidate,
    this.forgotCodeLabel,
    this.onForgotCode,
    this.debugAdminFlow = false,
  });

  final String title;
  final String label;
  final String invalidMessage;
  final String cancelLabel;
  final String submitLabel;
  final Future<bool> Function(String code) onValidate;
  final String? forgotCodeLabel;
  final VoidCallback? onForgotCode;
  final bool debugAdminFlow;

  @override
  State<_CodeEntryDialog> createState() => _CodeEntryDialogState();
}

class _CodeEntryDialogState extends State<_CodeEntryDialog> {
  final _controller = TextEditingController();
  String? _error;
  var _submitting = false;
  var _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncInputState);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncInputState);
    _controller.dispose();
    super.dispose();
  }

  void _syncInputState() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput == _hasInput) return;
    setState(() {
      _hasInput = hasInput;
      if (hasInput) _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SecureCodeTextField(
        controller: _controller,
        label: widget.label,
        autofocus: true,
        enabled: !_submitting,
        errorText: _error,
        onSubmitted: (_) {
          if (_hasInput) _submit();
        },
      ),
      actions: [
        if (widget.forgotCodeLabel != null && widget.onForgotCode != null)
          TextButton(
            onPressed: _submitting ? null : widget.onForgotCode,
            child: Text(widget.forgotCodeLabel!),
          ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submitting || !_hasInput ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_hasInput) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final ok = await widget.onValidate(_controller.text);
      if (!mounted) return;
      if (ok) {
        if (widget.debugAdminFlow) {
          debugPrint('Closing admin dialog');
        }
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _submitting = false;
        _error = widget.invalidMessage;
      });
    } catch (e, stackTrace) {
      if (widget.debugAdminFlow) {
        debugPrint('Admin code error: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = widget.invalidMessage;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.invalidMessage)));
    }
  }
}

typedef _RecoveryResetCallback =
    Future<({String familyCode, String adminCode, String modificationCode})>
    Function({
      required String recoveryCode,
      required String familyAccessCode,
      required String adminKpiCode,
      required String modificationCode,
      required bool generateAll,
    });

class _SuperAdminRecoveryCodeDialog extends StatefulWidget {
  const _SuperAdminRecoveryCodeDialog({required this.onValidate});

  final Future<bool> Function(String code) onValidate;

  @override
  State<_SuperAdminRecoveryCodeDialog> createState() =>
      _SuperAdminRecoveryCodeDialogState();
}

class _SuperAdminRecoveryCodeDialogState
    extends State<_SuperAdminRecoveryCodeDialog> {
  final _controller = TextEditingController();
  String? _error;
  var _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.superAdminRecovery),
      content: SizedBox(
        width: 420,
        child: SecureCodeTextField(
          controller: _controller,
          label: l10n.enterSuperAdminRecoveryCode,
          autofocus: true,
          enabled: !_submitting,
          errorText: _error,
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.enter),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_controller.text.trim().isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await widget.onValidate(_controller.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recoveryCodeAccepted)));
      Navigator.pop(context, _controller.text);
      return;
    }
    setState(() {
      _submitting = false;
      _error = l10n.recoveryCodeInvalid;
    });
  }
}

class _SuperAdminResetCodesDialog extends StatefulWidget {
  const _SuperAdminResetCodesDialog({
    required this.recoveryCode,
    required this.onReset,
  });

  final String recoveryCode;
  final _RecoveryResetCallback onReset;

  @override
  State<_SuperAdminResetCodesDialog> createState() =>
      _SuperAdminResetCodesDialogState();
}

class _SuperAdminResetCodesDialogState
    extends State<_SuperAdminResetCodesDialog> {
  final _familyCode = TextEditingController();
  final _adminCode = TextEditingController();
  final _modificationCode = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _familyCode.dispose();
    _adminCode.dispose();
    _modificationCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.resetCodes),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecureCodeTextField(
              controller: _familyCode,
              label: l10n.familyAccessCode,
              enabled: !_submitting,
            ),
            const SizedBox(height: 12),
            SecureCodeTextField(
              controller: _adminCode,
              label: l10n.adminAccessCode,
              enabled: !_submitting,
            ),
            const SizedBox(height: 12),
            SecureCodeTextField(
              controller: _modificationCode,
              label: l10n.enterModificationCode,
              enabled: !_submitting,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        OutlinedButton.icon(
          onPressed: _submitting ? null : () => _confirmAndReset(true),
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: Text(l10n.resetAllCodes),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : () => _confirmAndReset(false),
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.generateNewCodes),
        ),
      ],
    );
  }

  Future<void> _confirmAndReset(bool generateAll) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetCodes),
        content: Text(l10n.confirmResetCodes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resetCodes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.onReset(
        recoveryCode: widget.recoveryCode,
        familyAccessCode: _familyCode.text,
        adminKpiCode: _adminCode.text,
        modificationCode: _modificationCode.text,
        generateAll: generateAll,
      );
      if (!mounted) return;
      await _showGeneratedCodes(result);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.recoveryCodeInvalid;
      });
    }
  }

  Future<void> _showGeneratedCodes(
    ({String familyCode, String adminCode, String modificationCode}) result,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.codesResetSuccess),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.newGeneratedCode),
            const SizedBox(height: 12),
            SelectableText('${l10n.familyAccessCode}: ${result.familyCode}'),
            SelectableText('${l10n.adminAccessCode}: ${result.adminCode}'),
            SelectableText(
              '${l10n.enterModificationCode}: ${result.modificationCode}',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.finishTutorial),
          ),
        ],
      ),
    );
  }
}

class _OptionalFamilyLeadershipBanner extends ConsumerWidget {
  const _OptionalFamilyLeadershipBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value;
    final leader = ref.watch(familyLeaderProvider);
    if (data == null ||
        leader == null ||
        !data.familyLeadership.showLeaderBanner) {
      return const SizedBox.shrink();
    }
    final familyName = data.mainFamilyCode.trim().isEmpty
        ? 'Famille'
        : 'Famille ${data.mainFamilyCode.toUpperCase()}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E5),
        border: Border(bottom: BorderSide(color: Color(0xFFE8D69A))),
      ),
      child: Text(
        '$familyName · Sous la conduite de ${leader.fullName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF725516),
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
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

class _NavigationDrawer extends ConsumerWidget {
  const _NavigationDrawer({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final title = appSettings.applicationTitle.trim().isEmpty
        ? AppLocalizations.of(context).appTitle
        : appSettings.applicationTitle.trim();
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              ListTile(
                minLeadingWidth: 28,
                selected: i == selectedIndex,
                leading: i == selectedIndex
                    ? destinations[i].selectedIcon ?? destinations[i].icon
                    : destinations[i].icon,
                title: Text(destinations[i].label),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => onDestinationSelected(i),
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
