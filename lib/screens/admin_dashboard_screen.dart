import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/access_code.dart';
import '../models/app_settings.dart';
import '../models/bug_report.dart';
import '../models/family_announcement.dart';
import '../models/family_honor.dart';
import '../models/family_leadership.dart';
import '../models/family_tree_data.dart';
import '../models/firebase_user_role.dart';
import '../models/info_news.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/admin_access_service.dart';
import 'branding_settings_screen.dart';
import '../widgets/admin_contact_card.dart';
import '../widgets/bug_report_button.dart';
import '../widgets/bug_report_card.dart';
import '../widgets/edit_application_title_dialog.dart';
import '../widgets/kpi_card.dart';
import '../widgets/responsive.dart';
import '../widgets/secure_code_text_field.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('AdminDashboardScreen init');
    Future.microtask(() async {
      try {
        debugPrint('KPI loading started');
        await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
        debugPrint('KPI loading success');
      } catch (error) {
        debugPrint('KPI loading failed: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dataState = ref.watch(familyTreeProvider);
    final auth = ref.watch(authSessionProvider);
    return dataState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.adminDashboard)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.adminDashboard)),
        body: _AdminDashboardError(
          message: 'Erreur chargement Admin/KPI : $error',
        ),
      ),
      data: (data) {
        try {
          return _buildDashboard(context, l10n, auth, data);
        } catch (error, stackTrace) {
          debugPrint('Admin KPI error: $error');
          debugPrintStack(stackTrace: stackTrace);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.adminDashboard)),
            body: _AdminDashboardError(
              message: 'Erreur chargement Admin/KPI : $error',
            ),
          );
        }
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    AppLocalizations l10n,
    AuthState auth,
    FamilyTreeData data,
  ) {
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    final rotationStatus = ref
        .watch(adminAccessServiceProvider)
        .rotationStatus(data);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboard)),
      body: ResponsivePage(
        children: [
          Text(l10n.adminKpi, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 4,
            mainAxisExtent: 126,
            children: [
              KpiCard(label: l10n.totalPeople, value: kpi.totalPeople),
              KpiCard(
                label: l10n.personAddedThisMonth,
                value: kpi.peopleAddedThisMonth,
              ),
              KpiCard(
                label: l10n.personModifiedThisMonth,
                value: kpi.peopleModifiedThisMonth,
              ),
              KpiCard(label: l10n.familiesCount, value: kpi.linkedFamilies),
              KpiCard(label: l10n.pendingCount, value: kpi.pendingFamilyLinks),
              KpiCard(label: l10n.activeCodes, value: kpi.activeCodes),
              KpiCard(label: l10n.expiredCodes, value: kpi.expiredCodes),
              KpiCard(label: l10n.activityLog, value: data.auditLog.length),
            ],
          ),
          const SizedBox(height: 24),
          _ApplicationSettingsSection(data: data),
          const SizedBox(height: 24),
          _SyncManagementSection(data: data),
          const SizedBox(height: 24),
          Text(
            l10n.adminSecurity,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(l10n.currentAdminCode),
                    subtitle: const Text('************'),
                    trailing: _RotationStatusChip(status: rotationStatus),
                  ),
                  const Divider(),
                  _InfoRow(
                    label: l10n.lastAdminCodeChange,
                    value: _formatDate(data.adminAccess.lastChangedAt),
                  ),
                  _InfoRow(
                    label: l10n.nextAdminCodeChange,
                    value: _formatDate(data.adminAccess.nextChangeDueAt),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed: auth.isSuperAdmin
                          ? () => _showChangeAdminCodeDialog(context, ref)
                          : null,
                      icon: const Icon(Icons.password_outlined),
                      label: Text(l10n.changeAdminCode),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.adminCodeHistory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...data.adminAccess.codeHistory.reversed.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: const Text('************'),
                      subtitle: Text(
                        [
                          item.createdAt.isEmpty
                              ? ''
                              : '${l10n.create}: ${_formatDate(item.createdAt)}',
                          item.expiredAt.isEmpty
                              ? ''
                              : '${l10n.expiredCodes}: ${_formatDate(item.expiredAt)}',
                        ].where((value) => value.isNotEmpty).join('\n'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _AccessCodeManagementSection(
            data: data,
            dataRole: auth.session?.role ?? 'viewer',
          ),
          const SizedBox(height: 24),
          _BugReportsSection(data: data),
          const SizedBox(height: 24),
          _InfoNewsManagementSection(data: data),
          const SizedBox(height: 24),
          _FamilyAnnouncementSection(data: data),
          const SizedBox(height: 24),
          _FamilyHonorSection(data: data),
          const SizedBox(height: 24),
          Text(
            l10n.manageAdmins,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (auth.isSuperAdmin) ...[
            _FirebaseRoleManagementSection(auth: auth),
            const SizedBox(height: 12),
          ],
          ...data.admins.map((admin) => AdminContactCard(admin: admin)),
          Text(l10n.activityLog, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...data.auditLog.reversed
              .take(30)
              .map(
                (log) => Card(
                  child: ListTile(
                    title: Text(log.action),
                    subtitle: Text(
                      [
                        log.date,
                        log.actorRole,
                        log.description,
                      ].where((value) => value.isNotEmpty).join('\n'),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showChangeAdminCodeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.changeAdminCode),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SecureCodeTextField(
                  controller: oldController,
                  label: l10n.oldAdminCode,
                ),
                const SizedBox(height: 12),
                SecureCodeTextField(
                  controller: newController,
                  label: l10n.newAdminCode,
                ),
                const SizedBox(height: 12),
                SecureCodeTextField(
                  controller: confirmController,
                  label: l10n.confirmNewAdminCode,
                  errorText: error,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final validation = _validateNewAdminCode(
                  oldController.text,
                  newController.text,
                  confirmController.text,
                  l10n,
                );
                if (validation != null) {
                  setDialogState(() => error = validation);
                  return;
                }
                try {
                  final auth = ref.read(authSessionProvider);
                  await ref
                      .read(familyTreeProvider.notifier)
                      .changeAdminAccessCode(
                        oldCode: oldController.text,
                        newCode: newController.text,
                        changedByAdminId:
                            auth.session?.familyCode ?? 'superAdmin',
                        actorRole: auth.session?.role ?? 'superAdmin',
                      );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (_) {
                  setDialogState(() => error = l10n.invalidAdminCode);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminCodeChanged)));
    }
  }

  String? _validateNewAdminCode(
    String oldCode,
    String newCode,
    String confirmCode,
    AppLocalizations l10n,
  ) {
    if (oldCode.trim().isEmpty) return l10n.oldAdminCode;
    if (newCode.trim().length < 8) return l10n.newAdminCode;
    if (oldCode.trim().toUpperCase() == newCode.trim().toUpperCase()) {
      return l10n.adminCodeRotationDue;
    }
    if (newCode.trim() != confirmCode.trim()) return l10n.confirmNewAdminCode;
    return null;
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _FirebaseRoleManagementSection extends ConsumerWidget {
  const _FirebaseRoleManagementSection({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesState = ref.watch(firebaseUserRolesProvider);
    final canManageRemoteRoles = auth.firebaseRole == 'superAdmin';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rôles Firebase',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: canManageRemoteRoles
                      ? () => _showRoleDialog(context, ref)
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              canManageRemoteRoles
                  ? 'Gestion des documents user_roles pour les comptes Firebase Auth existants.'
                  : 'Connectez-vous avec le compte Firebase Super Admin pour gérer les rôles Firestore.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            rolesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Rôles Firebase indisponibles : $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (roles) {
                if (roles.isEmpty) {
                  return const Text('Aucun rôle Firebase trouvé pour ayivon.');
                }
                return Column(
                  children: [
                    for (final role in roles)
                      _FirebaseRoleTile(
                        role: role,
                        canManage: canManageRemoteRoles,
                        onEdit: () =>
                            _showRoleDialog(context, ref, existing: role),
                        onToggleActive: () => _toggleActive(context, ref, role),
                        onDelete: role.uid == auth.firebaseUid
                            ? null
                            : () => _deleteRole(context, ref, role),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoleDialog(
    BuildContext context,
    WidgetRef ref, {
    FirebaseUserRole? existing,
  }) async {
    final uidController = TextEditingController(text: existing?.uid ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    var selectedRole = existing?.role ?? 'editor';
    var active = existing?.active ?? true;
    String? error;
    var submitting = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Ajouter un rôle' : 'Modifier le rôle',
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uidController,
                  enabled: existing == null && !submitting,
                  decoration: const InputDecoration(
                    labelText: 'UID Firebase Auth',
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'editor', child: Text('editor')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                    DropdownMenuItem(
                      value: 'superAdmin',
                      child: Text('superAdmin'),
                    ),
                  ],
                  onChanged: submitting
                      ? null
                      : (value) => setDialogState(() {
                          selectedRole = value ?? 'editor';
                        }),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: submitting
                      ? null
                      : (value) => setDialogState(() => active = value),
                  title: const Text('Actif'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        final service = ref.read(
                          firebaseUserRoleServiceProvider,
                        );
                        if (service == null) {
                          throw StateError('Firebase non initialisé.');
                        }
                        await service.upsertRole(
                          uid: uidController.text,
                          email: emailController.text,
                          role: selectedRole,
                          active: active,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        setDialogState(() {
                          submitting = false;
                          error = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    uidController.dispose();
    emailController.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rôle Firebase enregistré.')),
      );
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    FirebaseUserRole role,
  ) async {
    try {
      final service = ref.read(firebaseUserRoleServiceProvider);
      if (service == null) throw StateError('Firebase non initialisé.');
      await service.setActive(role.uid, !role.active);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteRole(
    BuildContext context,
    WidgetRef ref,
    FirebaseUserRole role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle Firebase'),
        content: Text('Supprimer le rôle de ${role.email} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final service = ref.read(firebaseUserRoleServiceProvider);
      if (service == null) throw StateError('Firebase non initialisé.');
      await service.deleteRole(role.uid);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _FirebaseRoleTile extends StatelessWidget {
  const _FirebaseRoleTile({
    required this.role,
    required this.canManage,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final FirebaseUserRole role;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        role.active ? Icons.verified_user : Icons.block,
        color: role.active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      title: Text(role.email.isEmpty ? role.uid : role.email),
      subtitle: Text(
        [
          'UID: ${role.uid}',
          'role: ${role.role}',
          'familyIds: ${role.familyIds.join(', ')}',
          'active: ${role.active}',
        ].join('\n'),
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Modifier',
            onPressed: canManage ? onEdit : null,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: role.active ? 'Désactiver' : 'Activer',
            onPressed: canManage ? onToggleActive : null,
            icon: Icon(role.active ? Icons.toggle_on : Icons.toggle_off),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: canManage ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ApplicationSettingsSection extends ConsumerWidget {
  const _ApplicationSettingsSection({required this.data});

  final FamilyTreeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final settings = data.appSettings;
    final subtitle = settings.applicationSubtitle.trim();
    final canEdit = auth.isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.applicationSettings,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: canEdit ? () => _edit(context, ref) : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editApplicationTitle),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: canEdit
                  ? () => _recalculateGenerations(context, ref)
                  : null,
              icon: const Icon(Icons.family_restroom_outlined),
              label: Text(l10n.recalculateGenerations),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: canEdit ? () => _reloadData(context, ref) : null,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Recharger les données'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.title_outlined),
                  title: Text(l10n.applicationTitle),
                  subtitle: Text(settings.applicationTitle),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.short_text_outlined),
                  title: Text(l10n.applicationSubtitle),
                  subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(l10n.officialFamilyName),
                  subtitle: Text(
                    settings.officialFamilyName.trim().isEmpty
                        ? '-'
                        : settings.officialFamilyName.trim(),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.zoom_out_map_outlined),
                  title: Text(l10n.treeInitialZoom),
                  subtitle: Text(
                    '${(settings.treeSettings.initialZoom * 100).round()}%',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.history_toggle_off_outlined),
                  value: settings.treeSettings.rememberLastZoom,
                  onChanged: null,
                  title: Text(l10n.rememberLastZoom),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.groups_2_outlined),
                  value: settings.treeSettings.showMembersCounter,
                  onChanged: null,
                  title: Text(l10n.showMembersCounter),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.family_restroom_outlined),
                  value: settings.treeSettings.showGenerationBadges,
                  onChanged: null,
                  title: Text(l10n.showGenerationBadges),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.school_outlined),
                  value: settings.tutorialSettings.showFloatingHelpButton,
                  onChanged: null,
                  title: Text(l10n.showTutorial),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.auto_stories_outlined),
                  value: settings.tutorialSettings.showTutorialOnFirstLaunch,
                  onChanged: null,
                  title: Text(l10n.firstLaunchTutorial),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.visualIdentity),
            subtitle: Text(l10n.familyLogo),
            trailing: const Icon(Icons.chevron_right),
            enabled: canEdit,
            onTap: canEdit
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BrandingSettingsScreen(),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final next = await showDialog<AppSettings>(
      context: context,
      builder: (context) =>
          EditApplicationTitleDialog(settings: data.appSettings),
    );
    if (next == null) return;
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .updateAppSettings(
          next,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.applicationSettings)));
  }

  Future<void> _recalculateGenerations(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .recalculateGenerations(
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.recalculateGenerations)));
  }

  Future<void> _reloadData(BuildContext context, WidgetRef ref) async {
    await ref.read(familyTreeProvider.notifier).initializeAppFresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données rechargées et arbre recentré')),
    );
  }
}

class _SyncManagementSection extends ConsumerWidget {
  const _SyncManagementSection({required this.data});

  final FamilyTreeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = data.appSettings.storageSettings;
    final pending = data.pendingSyncQueue
        .where((item) => item.status != 'synced')
        .toList();
    final errors = pending.where((item) => item.status == 'failed').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synchronisation', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(label: 'Mode de stockage', value: storage.mode),
                _InfoRow(
                  label: 'Dernière synchronisation',
                  value: storage.lastSyncAt.isEmpty ? '-' : storage.lastSyncAt,
                ),
                _InfoRow(label: 'Statut', value: storage.syncStatus),
                _InfoRow(
                  label: 'Opérations en attente',
                  value: pending.length.toString(),
                ),
                _InfoRow(
                  label: 'Erreurs de synchronisation',
                  value: errors.length.toString(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(familyTreeProvider.notifier)
                            .syncPendingChanges();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Synchronisation lancée'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_outlined),
                      label: const Text('Synchroniser maintenant'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final raw = ref
                            .read(importExportServiceProvider)
                            .serialize(data);
                        await Clipboard.setData(ClipboardData(text: raw));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON copié')),
                        );
                      },
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Exporter JSON'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['json'],
                          withData: true,
                        );
                        final file = result?.files.single;
                        final bytes = file?.bytes;
                        if (bytes == null) return;
                        final raw = utf8.decode(bytes);
                        final imported = ref
                            .read(importExportServiceProvider)
                            .parse(raw);
                        await ref
                            .read(familyTreeProvider.notifier)
                            .importData(imported, merge: true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON importé')),
                        );
                      },
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Importer JSON'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['json'],
                          withData: true,
                        );
                        final file = result?.files.single;
                        final bytes = file?.bytes;
                        if (bytes == null) return;
                        final raw = utf8.decode(bytes);
                        final restored = ref
                            .read(importExportServiceProvider)
                            .parse(raw);
                        await ref
                            .read(familyTreeProvider.notifier)
                            .importData(restored, merge: false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sauvegarde restaurée')),
                        );
                      },
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restaurer depuis sauvegarde'),
                    ),
                  ],
                ),
                if (errors.isNotEmpty) ...[
                  const Divider(height: 28),
                  for (final item in errors.take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sync_problem_outlined),
                      title: Text('${item.entityType}:${item.entityId}'),
                      subtitle: Text(item.lastError),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BugReportsSection extends ConsumerStatefulWidget {
  const _BugReportsSection({required this.data});

  final FamilyTreeData data;

  @override
  ConsumerState<_BugReportsSection> createState() => _BugReportsSectionState();
}

class _BugReportsSectionState extends ConsumerState<_BugReportsSection> {
  var _status = 'all';
  var _priority = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final service = ref.watch(bugReportServiceProvider);
    final bugs = service.filter(
      widget.data,
      status: _status,
      priority: _priority,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.bugReports,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const BugReportButton(initialScreen: 'AdminDashboardScreen'),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: _status,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tous')),
                DropdownMenuItem(value: 'open', child: Text(l10n.bugOpen)),
                DropdownMenuItem(
                  value: 'inProgress',
                  child: Text(l10n.bugInProgress),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text(l10n.bugResolved),
                ),
                DropdownMenuItem(
                  value: 'deleted',
                  child: Text(l10n.bugDeleted),
                ),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            DropdownButton<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Toutes priorités')),
                DropdownMenuItem(value: 'low', child: Text('Faible')),
                DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                DropdownMenuItem(value: 'high', child: Text('Haute')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? _priority),
            ),
            OutlinedButton.icon(
              onPressed: bugs.isEmpty
                  ? null
                  : () => _exportJson(context, service.exportJson(bugs)),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exporter JSON'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (bugs.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.bugReports),
              subtitle: const Text('Aucun bug signalé.'),
            ),
          )
        else
          ...bugs.map(
            (bug) => BugReportCard(
              bug: bug,
              onInProgress: auth.isAdmin
                  ? () => _setStatus(context, bug, 'inProgress')
                  : null,
              onResolved: auth.isAdmin
                  ? () => _setStatus(context, bug, 'resolved')
                  : null,
              onDelete: auth.isAdmin ? () => _delete(context, bug) : null,
              onContact: bug.reportedByContact.trim().isEmpty
                  ? null
                  : () => _contactReporter(bug),
            ),
          ),
      ],
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    BugReport bug,
    String status,
  ) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .updateBugReportStatus(
          bug,
          status: status,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).bugStatus)),
    );
  }

  Future<void> _delete(BuildContext context, BugReport bug) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBugReport),
        content: Text(l10n.confirmDeleteBugReport),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteBugReport),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .deleteBugReport(
          bug,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _contactReporter(BugReport bug) async {
    final contact = bug.reportedByContact.trim();
    final message =
        'Bonjour ${bug.reportedByName},\nNous vous contactons au sujet du bug signalé : ${bug.title}.';
    final communication = ref.read(communicationServiceProvider);
    if (contact.contains('@')) {
      await communication.sendEmail(
        email: contact,
        subject: bug.title,
        body: message,
      );
    } else {
      await communication.openWhatsApp(phoneNumber: contact, message: message);
    }
  }

  Future<void> _exportJson(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Export JSON copié.')));
  }
}

class _AdminDashboardError extends StatelessWidget {
  const _AdminDashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Color(0xFFB3261E),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoNewsManagementSection extends ConsumerStatefulWidget {
  const _InfoNewsManagementSection({required this.data});

  final FamilyTreeData data;

  @override
  ConsumerState<_InfoNewsManagementSection> createState() =>
      _InfoNewsManagementSectionState();
}

class _InfoNewsManagementSectionState
    extends ConsumerState<_InfoNewsManagementSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(familyTreeProvider.notifier).cleanOldInfoNewsSendHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final canManage = auth.isAdmin;
    final logs = widget.data.infoNewsSendLogs
        .where(
          (log) =>
              log.status == 'pending' ||
              log.status == 'opened' ||
              log.status == 'failed',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.infoNewsManagement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: canManage ? () => _showDialog(context, ref) : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addInfoNews),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final news in widget.data.infoNews)
          Card(
            child: ListTile(
              leading: Icon(
                news.isActive
                    ? Icons.campaign_outlined
                    : Icons.campaign_outlined,
                color: news.isActive ? const Color(0xFF4D742B) : null,
              ),
              title: Text(news.title.isEmpty ? l10n.infoNews : news.title),
              subtitle: Text(
                [
                  news.message,
                  '${l10n.priority}: ${news.priority}',
                  news.startAt.isEmpty
                      ? ''
                      : '${l10n.startAt}: ${news.startAt}',
                  news.endAt.isEmpty ? '' : '${l10n.endAt}: ${news.endAt}',
                ].where((value) => value.isNotEmpty).join('\n'),
              ),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: news.isActive
                        ? l10n.disableAccessCode
                        : l10n.enableAccessCode,
                    onPressed: canManage
                        ? () => _save(
                            ref,
                            news.copyWith(isActive: !news.isActive),
                          )
                        : null,
                    icon: Icon(
                      news.isActive
                          ? Icons.toggle_on_outlined
                          : Icons.toggle_off_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.editInfoNews,
                    onPressed: canManage
                        ? () => _showDialog(context, ref, news)
                        : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.deleteInfoNews,
                    onPressed: canManage ? () => _delete(ref, news) : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ...[
          const SizedBox(height: 12),
          Text(
            l10n.infoNewsSendLog,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.freeWhatsAppQueue,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.historyCleanupNotice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.historiesKept}: ${widget.data.infoNewsSendLogs.length} · '
            '${l10n.lastCleanup}: ${_formatCleanupDate(widget.data.infoNewsSendHistoryLastCleanedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: logs.isEmpty
                  ? null
                  : () => _openNextWhatsApp(context, ref, logs),
              icon: const Icon(Icons.skip_next_outlined),
              label: Text(l10n.nextContact),
            ),
          ),
          const SizedBox(height: 8),
          for (final log in logs.take(8))
            ListTile(
              dense: true,
              leading: const Icon(Icons.send_outlined),
              title: Text(log.contactName),
              subtitle: Text(
                '${log.contactPhone} - ${_sendStatusLabel(l10n, log.status)}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: l10n.sendViaWhatsApp,
                    onPressed: () => _openWhatsApp(context, ref, log),
                    icon: const Icon(Icons.chat_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.copyMessage,
                    onPressed: () => _copyWhatsAppMessage(context, ref, log),
                    icon: const Icon(Icons.copy_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.markAsSent,
                    onPressed: () => _markSendLog(ref, log, 'sent'),
                    icon: const Icon(Icons.done_all_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.skipContact,
                    onPressed: () => _markSendLog(ref, log, 'skipped'),
                    icon: const Icon(Icons.skip_next_outlined),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, [
    InfoNews? news,
  ]) async {
    final l10n = AppLocalizations.of(context);
    final title = TextEditingController(text: news?.title ?? '');
    final message = TextEditingController(text: news?.message ?? '');
    final priority = TextEditingController(text: '${news?.priority ?? 0}');
    final startAt = TextEditingController(text: news?.startAt ?? '');
    final endAt = TextEditingController(text: news?.endAt ?? '');
    var isActive = news?.isActive ?? true;
    var sendToContacts = news?.sendToContacts ?? false;

    final saved = await showDialog<InfoNews>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(news == null ? l10n.addInfoNews : l10n.editInfoNews),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: InputDecoration(labelText: l10n.infoNewsTitle),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: message,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.infoNewsMessage,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priority,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.priority),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: startAt,
                    decoration: InputDecoration(labelText: l10n.startAt),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: endAt,
                    decoration: InputDecoration(labelText: l10n.endAt),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: Text(l10n.infoNewsActive),
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sendToContacts,
                    title: Text(l10n.sendToContacts),
                    subtitle: Text(l10n.whatsappManualNotice),
                    onChanged: news == null
                        ? (value) =>
                              setDialogState(() => sendToContacts = value)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                InfoNews(
                  id: news?.id ?? '',
                  title: title.text.trim(),
                  message: message.text.trim(),
                  isActive: isActive,
                  priority: int.tryParse(priority.text) ?? 0,
                  startAt: startAt.text.trim(),
                  endAt: endAt.text.trim(),
                  sendToContacts: sendToContacts,
                  createdAt: news?.createdAt ?? '',
                  updatedAt: news?.updatedAt ?? '',
                  createdBy: news?.createdBy ?? '',
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    message.dispose();
    priority.dispose();
    startAt.dispose();
    endAt.dispose();
    if (saved != null) await _save(ref, saved);
  }

  Future<void> _save(WidgetRef ref, InfoNews news) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .upsertInfoNews(
          news,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _delete(WidgetRef ref, InfoNews news) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .deleteInfoNews(
          news,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _openNextWhatsApp(
    BuildContext context,
    WidgetRef ref,
    List<InfoNewsSendLog> logs,
  ) async {
    if (logs.isEmpty) return;
    await _openWhatsApp(context, ref, logs.first);
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    InfoNewsSendLog log,
  ) async {
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final news = data.infoNews
        .where((item) => item.id == log.infoNewsId)
        .firstOrNull;
    if (news == null) return;
    try {
      final message = ref.read(infoNewsServiceProvider).whatsappMessage(news);
      await ref
          .read(communicationServiceProvider)
          .openWhatsApp(phoneNumber: log.contactPhone, message: message);
      await ref
          .read(familyTreeProvider.notifier)
          .updateInfoNewsSendLog(log, status: 'opened');
    } catch (error) {
      await ref
          .read(familyTreeProvider.notifier)
          .updateInfoNewsSendLog(log, status: 'failed', error: '$error');
    }
  }

  Future<void> _copyWhatsAppMessage(
    BuildContext context,
    WidgetRef ref,
    InfoNewsSendLog log,
  ) async {
    final l10n = AppLocalizations.of(context);
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final news = data.infoNews
        .where((item) => item.id == log.infoNewsId)
        .firstOrNull;
    if (news == null) return;
    final message = ref.read(infoNewsServiceProvider).whatsappMessage(news);
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.messageCopied)));
    }
  }

  Future<void> _markSendLog(WidgetRef ref, InfoNewsSendLog log, String status) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateInfoNewsSendLog(log, status: status);
  }

  String _sendStatusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'pending' => l10n.pending,
      'opened' => l10n.whatsappOpened,
      'sent' => l10n.sent,
      'failed' => l10n.failed,
      'skipped' => l10n.skipped,
      _ => status,
    };
  }

  String _formatCleanupDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FamilyAnnouncementSection extends ConsumerWidget {
  const _FamilyAnnouncementSection({required this.data});

  final FamilyTreeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final settings = data.familyAnnouncementSettings;
    final history = data.familyAnnouncementHistory.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Annonces familiales',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.birthdayPopupsEnabled,
                  title: const Text('Popups anniversaires'),
                  onChanged: auth.isAdmin
                      ? (value) => _save(
                          ref,
                          auth,
                          settings.copyWith(birthdayPopupsEnabled: value),
                        )
                      : null,
                ),
                SwitchListTile(
                  value: settings.birthPopupsEnabled,
                  title: const Text('Popups nouvelles naissances'),
                  onChanged: auth.isAdmin
                      ? (value) => _save(
                          ref,
                          auth,
                          settings.copyWith(birthPopupsEnabled: value),
                        )
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: const Text('Message anniversaire'),
                  subtitle: Text(settings.birthdayMessage),
                  trailing: IconButton(
                    onPressed: auth.isAdmin
                        ? () => _editMessage(
                            context,
                            ref,
                            auth,
                            settings,
                            isBirthday: true,
                          )
                        : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.child_friendly_outlined),
                  title: const Text('Message naissance'),
                  subtitle: Text(settings.birthMessage),
                  trailing: IconButton(
                    onPressed: auth.isAdmin
                        ? () => _editMessage(
                            context,
                            ref,
                            auth,
                            settings,
                            isBirthday: false,
                          )
                        : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Historique des annonces',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Les historiques de plus de 3 mois sont automatiquement supprimés.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final item in history.take(8))
          ListTile(
            dense: true,
            leading: Icon(
              item.type == 'birthday'
                  ? Icons.cake_outlined
                  : Icons.child_friendly_outlined,
            ),
            title: Text(_personName(data, item.memberId)),
            subtitle: Text(
              '${item.type} · ${item.date} · ${item.whatsappStatus}',
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Marquer comme envoyé',
                  onPressed: auth.isAdmin
                      ? () => ref
                            .read(familyTreeProvider.notifier)
                            .updateFamilyAnnouncementStatus(item, 'sent')
                      : null,
                  icon: const Icon(Icons.done_all_outlined),
                ),
                IconButton(
                  tooltip: 'Ignorer',
                  onPressed: auth.isAdmin
                      ? () => ref
                            .read(familyTreeProvider.notifier)
                            .updateFamilyAnnouncementStatus(item, 'skipped')
                      : null,
                  icon: const Icon(Icons.skip_next_outlined),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editMessage(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
    FamilyAnnouncementSettings settings, {
    required bool isBirthday,
  }) async {
    final controller = TextEditingController(
      text: isBirthday ? settings.birthdayMessage : settings.birthMessage,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBirthday ? 'Message anniversaire' : 'Message naissance'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _save(
      ref,
      auth,
      isBirthday
          ? settings.copyWith(birthdayMessage: value)
          : settings.copyWith(birthMessage: value),
    );
  }

  Future<void> _save(
    WidgetRef ref,
    AuthState auth,
    FamilyAnnouncementSettings settings,
  ) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateFamilyAnnouncementSettings(
          settings,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  String _personName(FamilyTreeData data, String id) {
    return data.people.where((item) => item.id == id).firstOrNull?.fullName ??
        id;
  }
}

class _AccessCodeManagementSection extends ConsumerStatefulWidget {
  const _AccessCodeManagementSection({
    required this.data,
    required this.dataRole,
  });

  final FamilyTreeData data;
  final String dataRole;

  @override
  ConsumerState<_AccessCodeManagementSection> createState() =>
      _AccessCodeManagementSectionState();
}

class _AccessCodeManagementSectionState
    extends ConsumerState<_AccessCodeManagementSection> {
  final _visibleCodes = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final accessCodeService = ref.watch(accessCodeServiceProvider);
    final actorRole = auth.session?.role ?? 'viewer';
    final adminId = auth.session?.familyCode ?? '';
    final codes = accessCodeService.visibleCodes(widget.data, actorRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.codeManagement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCodeDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createAccessCode),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.codeType)),
                DataColumn(label: Text(l10n.codeRole)),
                DataColumn(label: Text(l10n.accessCodes)),
                DataColumn(label: Text(l10n.codeStatus)),
                DataColumn(label: Text(l10n.codeExpiration)),
                DataColumn(label: Text(l10n.codeUsage)),
                DataColumn(label: Text(l10n.createdBy)),
                const DataColumn(label: Text('Actions')),
              ],
              rows: codes
                  .map(
                    (code) => DataRow(
                      cells: [
                        DataCell(Text(_typeLabel(l10n, code.type))),
                        DataCell(Text(code.role)),
                        DataCell(
                          Text(
                            _visibleCodes.contains(code.id)
                                ? code.code
                                : '********',
                          ),
                        ),
                        DataCell(
                          Text(code.enabled ? l10n.accepted : l10n.refused),
                        ),
                        DataCell(
                          Text(
                            code.expiresAt.isEmpty
                                ? '-'
                                : _formatDate(code.expiresAt),
                          ),
                        ),
                        DataCell(
                          Text('${code.usedCount}/${code.maxUses ?? '∞'}'),
                        ),
                        DataCell(
                          Text(
                            code.createdByName.isEmpty
                                ? '-'
                                : code.createdByName,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: _visibleCodes.contains(code.id)
                                    ? l10n.hideCode
                                    : l10n.showCode,
                                icon: Icon(
                                  _visibleCodes.contains(code.id)
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => _toggleVisibility(code),
                              ),
                              IconButton(
                                tooltip: l10n.copyCode,
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyCode(code),
                              ),
                              IconButton(
                                tooltip: l10n.editAccessCode,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _showCodeDialog(context, code: code),
                              ),
                              IconButton(
                                tooltip: code.enabled
                                    ? l10n.disableAccessCode
                                    : l10n.enableAccessCode,
                                icon: Icon(
                                  code.enabled
                                      ? Icons.block_outlined
                                      : Icons.check_circle_outline,
                                ),
                                onPressed: () =>
                                    _setEnabled(code, !code.enabled),
                              ),
                              IconButton(
                                tooltip: l10n.deleteAccessCode,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteCode(code),
                              ),
                              IconButton(
                                tooltip: l10n.regenerateCode,
                                icon: const Icon(Icons.autorenew),
                                onPressed:
                                    accessCodeService.canRegenerate(
                                      code,
                                      actorRole: actorRole,
                                      adminId: adminId,
                                    )
                                    ? () => _regenerateCode(code)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCodeDialog(BuildContext context, {AccessCode? code}) async {
    final l10n = AppLocalizations.of(context);
    final label = TextEditingController(text: code?.label ?? '');
    final value = TextEditingController(text: code?.code ?? '');
    final family = TextEditingController(text: code?.familyCode ?? 'AYIVON');
    final expires = TextEditingController(text: code?.expiresAt ?? '');
    final maxUses = TextEditingController(
      text: code?.maxUses?.toString() ?? '',
    );
    final notes = TextEditingController(text: code?.notes ?? '');
    var type = code?.type ?? 'temporary';
    var role = code?.role ?? 'viewer';
    var manual = true;
    String? error;

    final saved = await showDialog<AccessCode>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            code == null ? l10n.createAccessCode : l10n.editAccessCode,
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: label,
                    decoration: InputDecoration(labelText: l10n.codeType),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: l10n.codeType),
                    items: const [
                      DropdownMenuItem(
                        value: 'familyAccess',
                        child: Text('familyAccess'),
                      ),
                      DropdownMenuItem(
                        value: 'adminKpi',
                        child: Text('adminKpi'),
                      ),
                      DropdownMenuItem(
                        value: 'modification',
                        child: Text('modification'),
                      ),
                      DropdownMenuItem(
                        value: 'linkedFamily',
                        child: Text('linkedFamily'),
                      ),
                      DropdownMenuItem(
                        value: 'temporary',
                        child: Text('temporary'),
                      ),
                    ],
                    onChanged: (next) =>
                        setDialogState(() => type = next ?? type),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: l10n.codeRole),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('public')),
                      DropdownMenuItem(value: 'viewer', child: Text('viewer')),
                      DropdownMenuItem(value: 'editor', child: Text('editor')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                      DropdownMenuItem(
                        value: 'superAdmin',
                        child: Text('superAdmin'),
                      ),
                    ],
                    onChanged: (next) =>
                        setDialogState(() => role = next ?? role),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(manual ? l10n.manualCode : l10n.generateCode),
                    value: manual,
                    onChanged: (next) {
                      setDialogState(() {
                        manual = next;
                        if (!manual) {
                          value.text = ref
                              .read(accessCodeServiceProvider)
                              .generateCode();
                        }
                      });
                    },
                  ),
                  SecureCodeTextField(
                    controller: value,
                    label: l10n.accessCodes,
                    errorText: error,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: family,
                    decoration: const InputDecoration(labelText: 'Famille'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: expires,
                    decoration: InputDecoration(labelText: l10n.codeExpiration),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: maxUses,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.maxUses),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    decoration: InputDecoration(labelText: l10n.notes),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (value.text.trim().length < 6) {
                  setDialogState(() => error = l10n.requiredField);
                  return;
                }
                Navigator.pop(
                  context,
                  AccessCode(
                    id: code?.id ?? '',
                    code: value.text,
                    label: label.text.isEmpty ? value.text : label.text,
                    type: type,
                    role: role,
                    familyCode: family.text,
                    createdByAdminId: code?.createdByAdminId ?? '',
                    createdByName: code?.createdByName ?? '',
                    createdAt: code?.createdAt ?? '',
                    updatedAt: code?.updatedAt ?? '',
                    expiresAt: expires.text,
                    maxUses: int.tryParse(maxUses.text),
                    usedCount: code?.usedCount ?? 0,
                    enabled: code?.enabled ?? true,
                    lastUsedAt: code?.lastUsedAt ?? '',
                    notes: notes.text,
                  ),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    value.dispose();
    family.dispose();
    expires.dispose();
    maxUses.dispose();
    notes.dispose();
    if (saved == null) return;
    await _saveCode(saved);
  }

  Future<void> _saveCode(AccessCode code) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authSessionProvider);
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .upsertAccessCode(
            code,
            actorRole: auth.session?.role ?? 'viewer',
            adminId: auth.session?.familyCode ?? '',
            adminName: auth.session?.role ?? '',
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('code_already_exists')
                ? l10n.codeAlreadyExists
                : error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _setEnabled(AccessCode code, bool enabled) async {
    if (code.isImportant &&
        !await _confirm(
          code.enabled
              ? 'Désactiver ce code important ?'
              : 'Réactiver ce code ?',
        )) {
      return;
    }
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .setAccessCodeEnabled(
          code,
          enabled: enabled,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _deleteCode(AccessCode code) async {
    if (!await _confirm('Supprimer ce code ?')) return;
    final auth = ref.read(authSessionProvider);
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .deleteAccessCode(
            code,
            actorRole: auth.session?.role ?? 'viewer',
            adminId: auth.session?.familyCode ?? '',
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _regenerateCode(AccessCode code) async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.confirmRegenerateCode)) return;
    final auth = ref.read(authSessionProvider);
    try {
      final newCode = await ref
          .read(familyTreeProvider.notifier)
          .regenerateAccessCode(
            code,
            actorRole: auth.session?.role ?? 'viewer',
            adminId: auth.session?.familyCode ?? '',
            adminName: auth.session?.role ?? '',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.codeRegenerated)));
      await _showNewCodeDialog(newCode);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showNewCodeDialog(AccessCode code) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newGeneratedCode),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                code.code,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Copiez ce code maintenant. Il ne sera pas affiché automatiquement ensuite.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.oldCodeDisabled),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code.code));
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.copyNewCode),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(AccessCode code) async {
    final auth = ref.read(authSessionProvider);
    await Clipboard.setData(ClipboardData(text: code.code));
    await ref
        .read(familyTreeProvider.notifier)
        .auditAccessCodeAction(
          'code_copied',
          code,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _toggleVisibility(AccessCode code) async {
    final auth = ref.read(authSessionProvider);
    setState(() {
      if (!_visibleCodes.add(code.id)) {
        _visibleCodes.remove(code.id);
      }
    });
    if (_visibleCodes.contains(code.id)) {
      await ref
          .read(familyTreeProvider.notifier)
          .auditAccessCodeAction(
            'code_viewed',
            code,
            actorRole: auth.session?.role ?? 'viewer',
            adminId: auth.session?.familyCode ?? '',
          );
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'familyAccess' => l10n.familyAccessCode,
      'adminKpi' => l10n.adminKpiCode,
      'modification' => l10n.modificationCode,
      'linkedFamily' => l10n.linkedFamilyCode,
      'temporary' => l10n.temporaryCode,
      _ => type,
    };
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FamilyHonorSection extends ConsumerWidget {
  const _FamilyHonorSection({required this.data});

  final FamilyTreeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final honor = data.familyHonor;
    final leadership = data.familyLeadership;
    final selected = honor.patriarchPersonId.isEmpty
        ? null
        : data.people
              .where((person) => person.id == honor.patriarchPersonId)
              .firstOrNull;
    final selectedLeader = leadership.currentLeaderPersonId.isEmpty
        ? null
        : data.people
              .where((person) => person.id == leadership.currentLeaderPersonId)
              .firstOrNull;
    final selectedFormerLeader = leadership.formerLeaderPersonId.isEmpty
        ? null
        : data.people
              .where((person) => person.id == leadership.formerLeaderPersonId)
              .firstOrNull;
    final selectedSuccessor = leadership.successorPersonId.isEmpty
        ? null
        : data.people
              .where((person) => person.id == leadership.successorPersonId)
              .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.familyDistinctions,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showPatriarchBadge),
                  value: honor.showPatriarchBadge,
                  onChanged: (value) => _save(
                    ref,
                    auth,
                    honor.copyWith(showPatriarchBadge: value),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selected?.id ?? '',
                  decoration: InputDecoration(labelText: l10n.selectPatriarch),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('-')),
                    ...data.people.map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.fullName),
                      ),
                    ),
                  ],
                  onChanged: (value) => _save(
                    ref,
                    auth,
                    honor.copyWith(patriarchPersonId: value ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: honor.badgePosition,
                  decoration: InputDecoration(labelText: l10n.badgePosition),
                  items: const [
                    DropdownMenuItem(value: 'topLeft', child: Text('topLeft')),
                    DropdownMenuItem(
                      value: 'topRight',
                      child: Text('topRight'),
                    ),
                    DropdownMenuItem(
                      value: 'bottomLeft',
                      child: Text('bottomLeft'),
                    ),
                    DropdownMenuItem(
                      value: 'bottomRight',
                      child: Text('bottomRight'),
                    ),
                  ],
                  onChanged: (value) => _save(
                    ref,
                    auth,
                    honor.copyWith(badgePosition: value ?? 'topLeft'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: honor.badgeStyle,
                  decoration: InputDecoration(labelText: l10n.badgeStyle),
                  items: const [
                    DropdownMenuItem(value: 'premium', child: Text('premium')),
                    DropdownMenuItem(value: 'simple', child: Text('simple')),
                    DropdownMenuItem(value: 'gold', child: Text('gold')),
                    DropdownMenuItem(value: 'green', child: Text('green')),
                  ],
                  onChanged: (value) => _save(
                    ref,
                    auth,
                    honor.copyWith(badgeStyle: value ?? 'premium'),
                  ),
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showLeaderInTopBar),
                  value: leadership.showLeaderInTopBar,
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(showLeaderInTopBar: value),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showLeaderBanner),
                  value: leadership.showLeaderBanner,
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(showLeaderBanner: value),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.familyLeader),
                  subtitle: Text(l10n.currentLeader),
                  value: leadership.showLeaderBadge,
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(showLeaderBadge: value),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showLeaderPhoto),
                  value: leadership.showLeaderPhoto,
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(showLeaderPhoto: value),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedLeader?.id ?? '',
                  decoration: InputDecoration(labelText: l10n.currentLeader),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('-')),
                    ...data.people.map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.fullName),
                      ),
                    ),
                  ],
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(currentLeaderPersonId: value ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedFormerLeader?.id ?? '',
                  decoration: InputDecoration(labelText: l10n.formerChief),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('-')),
                    ...data.people.map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.fullName),
                      ),
                    ),
                  ],
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(formerLeaderPersonId: value ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSuccessor?.id ?? '',
                  decoration: InputDecoration(labelText: l10n.successor),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('-')),
                    ...data.people.map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.fullName),
                      ),
                    ),
                  ],
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(successorPersonId: value ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: leadership.title,
                  decoration: InputDecoration(labelText: l10n.chiefTitle),
                  onFieldSubmitted: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(
                      title: value.trim().isEmpty
                          ? 'Chef actuel'
                          : value.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: leadership.officialPhoto,
                  decoration: const InputDecoration(
                    labelText: 'Photo officielle',
                    hintText: 'Chemin local ou URL',
                  ),
                  onFieldSubmitted: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(officialPhoto: value.trim()),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: leadership.badgeStyle,
                  decoration: InputDecoration(labelText: l10n.badgeStyle),
                  items: const [
                    DropdownMenuItem(value: 'royal', child: Text('royal')),
                    DropdownMenuItem(
                      value: 'traditional',
                      child: Text('traditional'),
                    ),
                    DropdownMenuItem(value: 'premium', child: Text('premium')),
                    DropdownMenuItem(value: 'simple', child: Text('simple')),
                    DropdownMenuItem(value: 'gold', child: Text('gold')),
                    DropdownMenuItem(value: 'green', child: Text('green')),
                  ],
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(badgeStyle: value ?? 'royal'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: leadership.topBarLogoMode,
                  decoration: InputDecoration(labelText: l10n.topBarLogoMode),
                  items: [
                    DropdownMenuItem(
                      value: 'classicLogo',
                      child: Text(l10n.classicLogo),
                    ),
                    DropdownMenuItem(
                      value: 'logoAndLeader',
                      child: Text(l10n.logoAndLeader),
                    ),
                    DropdownMenuItem(
                      value: 'leaderOnly',
                      child: Text(l10n.leaderOnly),
                    ),
                  ],
                  onChanged: (value) => _saveLeadership(
                    ref,
                    auth,
                    leadership.copyWith(topBarLogoMode: value ?? 'leaderOnly'),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_remove_outlined),
                    label: Text(l10n.removeLeader),
                    onPressed: leadership.currentLeaderPersonId.isEmpty
                        ? null
                        : () => _saveLeadership(
                            ref,
                            auth,
                            leadership.copyWith(currentLeaderPersonId: ''),
                          ),
                  ),
                ),
                if (data.familyLeadershipHistory.isNotEmpty) ...[
                  const Divider(height: 32),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.leadershipHistory,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in data.familyLeadershipHistory.take(4))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(entry.title),
                      subtitle: Text(
                        [
                          entry.personId,
                          if (entry.startDate.isNotEmpty) entry.startDate,
                          if (entry.endDate.isNotEmpty) entry.endDate,
                        ].join(' · '),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(WidgetRef ref, AuthState auth, FamilyHonor familyHonor) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateFamilyHonor(
          familyHonor,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _saveLeadership(
    WidgetRef ref,
    AuthState auth,
    FamilyLeadership familyLeadership,
  ) {
    return ref
        .read(familyTreeProvider.notifier)
        .updateFamilyLeadership(
          familyLeadership,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }
}

class _RotationStatusChip extends StatelessWidget {
  const _RotationStatusChip({required this.status});

  final AdminCodeRotationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (status) {
      AdminCodeRotationStatus.upToDate => l10n.validModificationCode,
      AdminCodeRotationStatus.dueSoon => l10n.adminCodeRotationDue,
      AdminCodeRotationStatus.late => l10n.adminCodeRotationLate,
    };
    final color = switch (status) {
      AdminCodeRotationStatus.upToDate => Colors.green,
      AdminCodeRotationStatus.dueSoon => Colors.orange,
      AdminCodeRotationStatus.late => Colors.red,
    };
    return Chip(
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color.shade700, fontWeight: FontWeight.w700),
    );
  }
}

extension _FirstOrNullPerson<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
