import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/access_code.dart';
import '../models/admin_notification_settings.dart';
import '../models/app_settings.dart';
import '../models/bug_report.dart';
import '../models/diagnostic_report.dart';
import '../models/family_announcement.dart';
import '../models/family_honor.dart';
import '../models/family_leadership.dart';
import '../models/family_tree_data.dart';
import '../models/firebase_user_role.dart';
import '../models/info_news.dart';
import '../models/sync_incident.dart';
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

enum _AdminCenterSection {
  dashboard,
  members,
  users,
  accessCodes,
  synchronization,
  incidents,
  diagnostic,
  activityLog,
  statistics,
  settings,
  security,
  backups,
  about,
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _AdminCenterSection _selectedSection = _AdminCenterSection.dashboard;

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
    final sectionTitle = _adminSectionLabel(l10n, _selectedSection);
    return Scaffold(
      appBar: AppBar(title: Text(sectionTitle)),
      drawer: _AdminCenterDrawer(
        selected: _selectedSection,
        data: data,
        onSelect: _selectAdminSection,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = ResponsivePage(
            children: _adminSectionChildren(context, l10n, auth, data),
          );
          if (constraints.maxWidth < 1000) return content;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _AdminCenterSideNavigation(
                  selected: _selectedSection,
                  data: data,
                  onSelect: _selectAdminSection,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  void _selectAdminSection(_AdminCenterSection section) {
    setState(() => _selectedSection = section);
  }

  List<Widget> _adminSectionChildren(
    BuildContext context,
    AppLocalizations l10n,
    AuthState auth,
    FamilyTreeData data,
  ) {
    return switch (_selectedSection) {
      _AdminCenterSection.dashboard => _dashboardChildren(context, l10n, data),
      _AdminCenterSection.members => _membersChildren(context, l10n, data),
      _AdminCenterSection.users => _usersChildren(context, l10n, auth, data),
      _AdminCenterSection.accessCodes => [
        _AccessCodeManagementSection(
          data: data,
          dataRole: auth.session?.role ?? auth.firebaseRole ?? 'viewer',
        ),
      ],
      _AdminCenterSection.synchronization => [
        _SyncManagementSection(data: data),
      ],
      _AdminCenterSection.incidents => _incidentsChildren(context, data),
      _AdminCenterSection.diagnostic => [_DiagnosticCenterSection(data: data)],
      _AdminCenterSection.activityLog => _activityLogChildren(l10n, data),
      _AdminCenterSection.statistics => _statisticsChildren(
        context,
        l10n,
        data,
      ),
      _AdminCenterSection.settings => _settingsChildren(data),
      _AdminCenterSection.security => _securityChildren(
        context,
        l10n,
        auth,
        data,
      ),
      _AdminCenterSection.backups => _backupsChildren(context, data),
      _AdminCenterSection.about => _aboutChildren(context, data),
    };
  }

  List<Widget> _dashboardChildren(
    BuildContext context,
    AppLocalizations l10n,
    FamilyTreeData data,
  ) {
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    final incidents = _syncIncidents(data);
    final criticalCount = incidents
        .where((item) => item.severity == 'critical')
        .length;
    final failedSyncCount = data.pendingSyncQueue
        .where((item) => item.status == 'failed')
        .length;
    return [
      Text('Tableau de bord', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ResponsiveGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 4,
        mainAxisExtent: 126,
        children: [
          KpiCard(label: l10n.totalPeople, value: kpi.totalPeople),
          KpiCard(label: l10n.familiesCount, value: kpi.linkedFamilies),
          KpiCard(label: 'Administrateurs', value: data.admins.length),
          KpiCard(label: 'Synchronisation', value: failedSyncCount),
          KpiCard(label: 'Incidents critiques', value: criticalCount),
          KpiCard(label: l10n.activityLog, value: data.auditLog.length),
          KpiCard(label: l10n.activeCodes, value: kpi.activeCodes),
          KpiCard(label: l10n.expiredCodes, value: kpi.expiredCodes),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () =>
                _selectAdminSection(_AdminCenterSection.synchronization),
            icon: const Icon(Icons.sync_outlined),
            label: const Text('Synchroniser'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                _selectAdminSection(_AdminCenterSection.diagnostic),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('Diagnostic'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                _selectAdminSection(_AdminCenterSection.activityLog),
            icon: const Icon(Icons.history_outlined),
            label: const Text('Journal'),
          ),
          OutlinedButton.icon(
            onPressed: () => _selectAdminSection(_AdminCenterSection.users),
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Utilisateurs'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoRow(
                label: 'Dernière synchronisation',
                value: data.syncSettings.lastSyncAt.isEmpty
                    ? '-'
                    : data.syncSettings.lastSyncAt,
              ),
              _InfoRow(
                label: 'Dernière sauvegarde',
                value: data.lastUpdatedAt.isEmpty ? '-' : data.lastUpdatedAt,
              ),
              _InfoRow(
                label: 'Activité récente',
                value: data.auditLog.isEmpty ? '-' : data.auditLog.last.action,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _membersChildren(
    BuildContext context,
    AppLocalizations l10n,
    FamilyTreeData data,
  ) {
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    return [
      Text('Membres', style: Theme.of(context).textTheme.titleLarge),
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
        ],
      ),
      const SizedBox(height: 12),
      const _AdminSectionNote(
        icon: Icons.people_alt_outlined,
        title: 'Gestion des membres',
        message:
            'Les actions Ajouter, Modifier et Supprimer restent disponibles depuis l’arbre familial et les fiches membres.',
      ),
    ];
  }

  List<Widget> _usersChildren(
    BuildContext context,
    AppLocalizations l10n,
    AuthState auth,
    FamilyTreeData data,
  ) {
    return [
      Text(l10n.manageAdmins, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (auth.isSuperAdmin) ...[
        _FirebaseRoleManagementSection(auth: auth),
        const SizedBox(height: 12),
      ],
      ...data.admins.map((admin) => AdminContactCard(admin: admin)),
    ];
  }

  List<Widget> _incidentsChildren(BuildContext context, FamilyTreeData data) {
    final incidents = _syncIncidents(data);
    return [
      Text('Incidents', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      _BugReportsSection(data: data),
      if (incidents.isNotEmpty) ...[
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SyncIncidentsPanel(incidents: incidents),
          ),
        ),
      ],
    ];
  }

  List<Widget> _activityLogChildren(
    AppLocalizations l10n,
    FamilyTreeData data,
  ) {
    return [
      Text(l10n.activityLog, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...data.auditLog.reversed
          .take(50)
          .map(
            (log) => Card(
              child: ListTile(
                leading: const Icon(Icons.history_outlined),
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
    ];
  }

  List<Widget> _statisticsChildren(
    BuildContext context,
    AppLocalizations l10n,
    FamilyTreeData data,
  ) {
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    return [
      Text('Statistiques', style: Theme.of(context).textTheme.titleLarge),
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
          KpiCard(label: 'Incidents', value: _syncIncidents(data).length),
        ],
      ),
    ];
  }

  List<Widget> _settingsChildren(FamilyTreeData data) {
    return [
      _ApplicationSettingsSection(data: data),
      const SizedBox(height: 24),
      _InfoNewsManagementSection(data: data),
      const SizedBox(height: 24),
      _FamilyAnnouncementSection(data: data),
      const SizedBox(height: 24),
      _FamilyHonorSection(data: data),
    ];
  }

  List<Widget> _securityChildren(
    BuildContext context,
    AppLocalizations l10n,
    AuthState auth,
    FamilyTreeData data,
  ) {
    final rotationStatus = ref
        .watch(adminAccessServiceProvider)
        .rotationStatus(data);
    return [
      Text(l10n.adminSecurity, style: Theme.of(context).textTheme.titleLarge),
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
      const SizedBox(height: 16),
      _SessionSecuritySection(auth: auth),
    ];
  }

  List<Widget> _backupsChildren(BuildContext context, FamilyTreeData data) {
    return [
      Text('Sauvegardes', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      _SyncManagementSection(data: data),
    ];
  }

  List<Widget> _aboutChildren(BuildContext context, FamilyTreeData data) {
    return [
      Text('A propos', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _InfoRow(label: 'Version', value: '1.0.0+1'),
              _InfoRow(label: 'Famille', value: data.mainFamilyCode),
              _InfoRow(
                label: 'Mode de stockage',
                value: data.syncSettings.storageMode,
              ),
              _InfoRow(
                label: 'Dernière mise à jour',
                value: data.lastUpdatedAt.isEmpty ? '-' : data.lastUpdatedAt,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<SyncIncident> _syncIncidents(FamilyTreeData data) {
    return data.pendingSyncQueue
        .where((item) => item.status == 'failed' || item.lastError.isNotEmpty)
        .map(
          (item) =>
              SyncIncident.fromPendingItem(item, familyId: data.mainFamilyCode),
        )
        .toList();
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

class _AdminCenterDrawer extends StatelessWidget {
  const _AdminCenterDrawer({
    required this.selected,
    required this.data,
    required this.onSelect,
  });

  final _AdminCenterSection selected;
  final FamilyTreeData data;
  final ValueChanged<_AdminCenterSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _AdminCenterNavigationList(
          selected: selected,
          data: data,
          onSelect: (section) {
            Navigator.pop(context);
            onSelect(section);
          },
        ),
      ),
    );
  }
}

class _AdminCenterSideNavigation extends StatelessWidget {
  const _AdminCenterSideNavigation({
    required this.selected,
    required this.data,
    required this.onSelect,
  });

  final _AdminCenterSection selected;
  final FamilyTreeData data;
  final ValueChanged<_AdminCenterSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: _AdminCenterNavigationList(
          selected: selected,
          data: data,
          onSelect: onSelect,
        ),
      ),
    );
  }
}

class _AdminCenterNavigationList extends StatelessWidget {
  const _AdminCenterNavigationList({
    required this.selected,
    required this.data,
    required this.onSelect,
  });

  final _AdminCenterSection selected;
  final FamilyTreeData data;
  final ValueChanged<_AdminCenterSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Text(
            'Centre d’administration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final section in _AdminCenterSection.values)
          _AdminCenterNavigationTile(
            selected: section == selected,
            label: _adminSectionLabel(l10n, section),
            icon: _adminSectionIcon(section),
            count: _adminSectionCount(section, data),
            onTap: () => onSelect(section),
          ),
      ],
    );
  }
}

class _AdminCenterNavigationTile extends StatelessWidget {
  const _AdminCenterNavigationTile({
    required this.selected,
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon),
        title: Text(label, overflow: TextOverflow.ellipsis),
        trailing: count == null
            ? null
            : Badge(
                label: Text(count.toString()),
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
        onTap: onTap,
      ),
    );
  }
}

class _AdminSectionNote extends StatelessWidget {
  const _AdminSectionNote({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

class _SessionSecuritySection extends ConsumerWidget {
  const _SessionSecuritySection({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesState = ref.watch(firebaseUserRolesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices_other_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: () => ref.invalidate(firebaseUserRolesProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _SessionPolicySummary(),
            const SizedBox(height: 12),
            rolesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Sessions indisponibles : $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (roles) {
                final sessions = roles
                    .where((role) => role.isAccessCodeSession || role.active)
                    .toList();
                if (sessions.isEmpty) {
                  return const Text('Aucune session active.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              ref.invalidate(firebaseUserRolesProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualiser'),
                        ),
                        OutlinedButton.icon(
                          onPressed: auth.isSuperAdmin
                              ? () => _confirmRevokeAll(context, ref)
                              : null,
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Déconnecter tous'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: sessions
                              .map(
                                (session) => SizedBox(
                                  width: wide
                                      ? (constraints.maxWidth - 12) / 2
                                      : constraints.maxWidth,
                                  child: _SessionCard(
                                    session: session,
                                    isCurrent: session.uid == auth.firebaseUid,
                                    canManage: auth.isSuperAdmin,
                                    onDetails: () =>
                                        _showSessionDetails(context, session),
                                    onRevoke: () => _revokeSession(
                                      context,
                                      ref,
                                      session.uid,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
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

  Future<void> _revokeSession(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    await ref.read(firebaseUserRoleServiceProvider)?.revokeSession(uid);
    ref.invalidate(firebaseUserRolesProvider);
  }

  Future<void> _confirmRevokeAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnecter les sessions'),
        content: const Text(
          'Déconnecter toutes les autres sessions par code d’accès ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(firebaseUserRoleServiceProvider)
        ?.revokeAllOtherAccessCodeSessions();
    ref.invalidate(firebaseUserRolesProvider);
  }

  Future<void> _showSessionDetails(
    BuildContext context,
    FirebaseUserRole session,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détail de la session'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionInlineInfo(
                label: 'Utilisateur',
                value: session.email.isEmpty ? session.uid : session.email,
              ),
              _SessionInlineInfo(label: 'UID', value: session.uid),
              _SessionInlineInfo(label: 'Rôle', value: session.role),
              _SessionInlineInfo(
                label: 'Famille',
                value: session.familyIds.join(', '),
              ),
              _SessionInlineInfo(
                label: 'Méthode',
                value: session.authMethod.isEmpty
                    ? 'Firebase'
                    : session.authMethod,
              ),
              _SessionInlineInfo(
                label: 'Appareil',
                value: _sessionPlatformLabel(session),
              ),
              _SessionInlineInfo(
                label: 'Connexion',
                value: _sessionDateLabel(
                  session.lastAuthenticatedAt ?? session.createdAt,
                ),
              ),
              _SessionInlineInfo(
                label: 'Expiration',
                value: _sessionExpiryLabel(session.sessionExpiresAt),
              ),
              _SessionInlineInfo(
                label: 'État',
                value: session.active ? 'Active' : 'Révoquée',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

String _sessionPlatformLabel(FirebaseUserRole role) {
  final method = role.authMethod.isEmpty ? 'Firebase' : role.authMethod;
  if (role.deviceFingerprintHash.isEmpty) return method;
  final fingerprint = role.deviceFingerprintHash.length <= 8
      ? role.deviceFingerprintHash
      : role.deviceFingerprintHash.substring(0, 8);
  return '$method / appareil $fingerprint';
}

String _sessionDateLabel(Object? value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is String) date = DateTime.tryParse(value);
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _sessionExpiryLabel(Object? value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is String) date = DateTime.tryParse(value);
  if (date == null) return 'Jusqu’à déconnexion';
  final difference = date.difference(DateTime.now());
  if (difference.isNegative) return 'Expirée';
  final days = difference.inDays;
  if (days >= 1) return 'Dans $days jour${days > 1 ? 's' : ''}';
  final hours = difference.inHours;
  if (hours >= 1) return 'Dans $hours h';
  final minutes = difference.inMinutes.clamp(1, 59);
  return 'Dans $minutes min';
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isCurrent,
    required this.canManage,
    required this.onDetails,
    required this.onRevoke,
  });

  final FirebaseUserRole session;
  final bool isCurrent;
  final bool canManage;
  final VoidCallback onDetails;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = session.email.isEmpty ? session.uid : session.email;
    final active = session.active;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : colorScheme.errorContainer.withValues(alpha: 0.35),
        border: Border.all(
          color: active ? colorScheme.outlineVariant : colorScheme.error,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.check_circle_outline : Icons.block_outlined,
                  color: active ? colorScheme.primary : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (isCurrent)
                  const Chip(
                    label: Text('Actuelle'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SessionInlineInfo(label: 'Rôle', value: session.role),
            _SessionInlineInfo(
              label: 'Famille',
              value: session.familyIds.join(', '),
            ),
            _SessionInlineInfo(
              label: 'Appareil',
              value: _sessionPlatformLabel(session),
            ),
            _SessionInlineInfo(
              label: 'Dernière activité',
              value: _sessionDateLabel(
                session.lastAuthenticatedAt ?? session.updatedAt,
              ),
            ),
            _SessionInlineInfo(
              label: 'Expire',
              value: _sessionExpiryLabel(session.sessionExpiresAt),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Voir le détail'),
                ),
                OutlinedButton.icon(
                  onPressed: canManage && active && !isCurrent
                      ? onRevoke
                      : null,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Déconnecter'),
                ),
                OutlinedButton.icon(
                  onPressed: canManage && active && !isCurrent
                      ? onRevoke
                      : null,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Bloquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionInlineInfo extends StatelessWidget {
  const _SessionInlineInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _SessionPolicySummary extends StatelessWidget {
  const _SessionPolicySummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paramètres de session', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            const _SessionPolicyRow(
              checked: true,
              label: 'Connexion automatique activée',
            ),
            const _SessionPolicyRow(
              checked: true,
              label: 'Mémoriser la connexion',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SessionDurationChip(label: '24 h'),
                _SessionDurationChip(label: '7 jours'),
                _SessionDurationChip(label: '30 jours', selected: true),
                _SessionDurationChip(label: '90 jours'),
                _SessionDurationChip(label: 'Jamais'),
              ],
            ),
            const SizedBox(height: 8),
            const _SessionPolicyRow(
              checked: true,
              label: 'Une session par appareil',
            ),
            const _SessionPolicyRow(
              checked: true,
              label: 'Déconnecter les appareils lors du changement du code',
            ),
            const _SessionPolicyRow(
              checked: true,
              label:
                  'Nouvelle authentification après 30 minutes pour modifier, supprimer, KPI, paramètres et sauvegardes',
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionPolicyRow extends StatelessWidget {
  const _SessionPolicyRow({required this.checked, required this.label});

  final bool checked;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _SessionDurationChip extends StatelessWidget {
  const _SessionDurationChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: null,
      visualDensity: VisualDensity.compact,
    );
  }
}

String _adminSectionLabel(AppLocalizations l10n, _AdminCenterSection section) {
  return switch (section) {
    _AdminCenterSection.dashboard => 'Tableau de bord',
    _AdminCenterSection.members => 'Membres',
    _AdminCenterSection.users => 'Utilisateurs',
    _AdminCenterSection.accessCodes => 'Codes d’accès',
    _AdminCenterSection.synchronization => 'Synchronisation',
    _AdminCenterSection.incidents => 'Incidents',
    _AdminCenterSection.diagnostic => 'Diagnostic',
    _AdminCenterSection.activityLog => l10n.activityLog,
    _AdminCenterSection.statistics => 'Statistiques',
    _AdminCenterSection.settings => 'Paramètres',
    _AdminCenterSection.security => 'Sécurité',
    _AdminCenterSection.backups => 'Sauvegardes',
    _AdminCenterSection.about => 'A propos',
  };
}

IconData _adminSectionIcon(_AdminCenterSection section) {
  return switch (section) {
    _AdminCenterSection.dashboard => Icons.dashboard_outlined,
    _AdminCenterSection.members => Icons.people_alt_outlined,
    _AdminCenterSection.users => Icons.manage_accounts_outlined,
    _AdminCenterSection.accessCodes => Icons.key_outlined,
    _AdminCenterSection.synchronization => Icons.sync_outlined,
    _AdminCenterSection.incidents => Icons.report_problem_outlined,
    _AdminCenterSection.diagnostic => Icons.health_and_safety_outlined,
    _AdminCenterSection.activityLog => Icons.history_outlined,
    _AdminCenterSection.statistics => Icons.query_stats_outlined,
    _AdminCenterSection.settings => Icons.settings_outlined,
    _AdminCenterSection.security => Icons.security_outlined,
    _AdminCenterSection.backups => Icons.backup_outlined,
    _AdminCenterSection.about => Icons.info_outline,
  };
}

int? _adminSectionCount(_AdminCenterSection section, FamilyTreeData data) {
  return switch (section) {
    _AdminCenterSection.members => data.people.length,
    _AdminCenterSection.users => data.admins.length,
    _AdminCenterSection.accessCodes => data.familyCodes.length,
    _AdminCenterSection.synchronization => data.pendingSyncQueue.length,
    _AdminCenterSection.incidents =>
      data.pendingSyncQueue
          .where((item) => item.status == 'failed' || item.lastError.isNotEmpty)
          .length,
    _AdminCenterSection.activityLog => data.auditLog.length,
    _ => null,
  };
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
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final title = Text(
              l10n.applicationSettings,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: canEdit ? () => _edit(context, ref) : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editApplicationTitle),
                ),
                OutlinedButton.icon(
                  onPressed: canEdit
                      ? () => _recalculateGenerations(context, ref)
                      : null,
                  icon: const Icon(Icons.family_restroom_outlined),
                  label: Text(l10n.recalculateGenerations),
                ),
                FilledButton.icon(
                  onPressed: canEdit ? () => _reloadData(context, ref) : null,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Recharger les données'),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 10), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: title),
                const SizedBox(width: 12),
                Flexible(child: actions),
              ],
            );
          },
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

enum _KpiSyncStatus { idle, syncing, success, partialSuccess, failure }

class _KpiSyncResult {
  const _KpiSyncResult({
    required this.total,
    required this.successCount,
    required this.failureCount,
    required this.completedAt,
    required this.status,
    this.errorMessage = '',
  });

  final int total;
  final int successCount;
  final int failureCount;
  final DateTime completedAt;
  final _KpiSyncStatus status;
  final String errorMessage;
}

class _SyncManagementSection extends ConsumerStatefulWidget {
  const _SyncManagementSection({required this.data});

  final FamilyTreeData data;

  @override
  ConsumerState<_SyncManagementSection> createState() =>
      _SyncManagementSectionState();
}

class _SyncManagementSectionState
    extends ConsumerState<_SyncManagementSection> {
  var _syncStatus = _KpiSyncStatus.idle;
  _KpiSyncResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final storage = data.appSettings.storageSettings;
    final pending = data.pendingSyncQueue
        .where((item) => item.status != 'synced' && item.status != 'resolved')
        .toList();
    final pendingCount = pending.length;
    final canSynchronize =
        pendingCount > 0 && _syncStatus != _KpiSyncStatus.syncing;
    final incidentItems = pending
        .where(
          (item) =>
              (item.status == 'failed' ||
                  item.status == 'inProgress' ||
                  item.status == 'resolved') &&
              item.lastError.isNotEmpty,
        )
        .toList();
    final incidents = incidentItems
        .map(
          (item) =>
              SyncIncident.fromPendingItem(item, familyId: data.mainFamilyCode),
        )
        .toList();
    final criticalCount = incidents
        .where((item) => item.severity == 'critical')
        .length;
    const notificationSettings = AdminNotificationSettings();
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
                  value: incidents.length.toString(),
                ),
                _InfoRow(
                  label: 'Incidents critiques',
                  value: criticalCount.toString(),
                ),
                const _ExternalNotificationsDisabledBanner(
                  settings: notificationSettings,
                ),
                if (_lastResult != null) ...[
                  const SizedBox(height: 12),
                  _SyncResultBanner(result: _lastResult!),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: canSynchronize
                          ? () => _synchronize(context, pending)
                          : null,
                      icon: _syncStatus == _KpiSyncStatus.syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_outlined),
                      label: Text(_syncButtonLabel(pendingCount)),
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
                if (incidents.isNotEmpty) ...[
                  const Divider(height: 28),
                  _SyncIncidentsPanel(incidents: incidents),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _syncButtonLabel(int pendingCount) {
    if (_syncStatus == _KpiSyncStatus.syncing) {
      return 'Synchronisation en cours...';
    }
    if (pendingCount == 0) return 'Aucune donnée à synchroniser';
    if (_lastResult?.status == _KpiSyncStatus.partialSuccess ||
        _lastResult?.status == _KpiSyncStatus.failure) {
      return 'Réessayer la synchronisation ($pendingCount)';
    }
    return 'Synchroniser ($pendingCount)';
  }

  Future<void> _synchronize(
    BuildContext context,
    List<dynamic> pendingBefore,
  ) async {
    if (_syncStatus == _KpiSyncStatus.syncing || pendingBefore.isEmpty) return;
    setState(() => _syncStatus = _KpiSyncStatus.syncing);
    final total = pendingBefore.length;
    try {
      final synced = await ref
          .read(familyTreeProvider.notifier)
          .syncPendingChanges();
      final pendingAfter = synced.pendingSyncQueue
          .where((item) => item.status != 'synced' && item.status != 'resolved')
          .toList();
      final failureCount = pendingAfter.length;
      final successCount = (total - failureCount).clamp(0, total);
      final status = failureCount == 0
          ? _KpiSyncStatus.success
          : successCount > 0
          ? _KpiSyncStatus.partialSuccess
          : _KpiSyncStatus.failure;
      final errorMessage = pendingAfter.isEmpty
          ? ''
          : _friendlySyncError(pendingAfter.first.lastError);
      final result = _KpiSyncResult(
        total: total,
        successCount: successCount,
        failureCount: failureCount,
        completedAt: DateTime.now(),
        status: status,
        errorMessage: errorMessage,
      );
      if (!mounted) return;
      setState(() {
        _syncStatus = status;
        _lastResult = result;
      });
      await _recordSyncAttempt(result);
      if (!context.mounted) return;
      _showSyncSnackBar(context, result);
    } catch (error, stackTrace) {
      debugPrint('KPI sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      final result = _KpiSyncResult(
        total: total,
        successCount: 0,
        failureCount: total,
        completedAt: DateTime.now(),
        status: _KpiSyncStatus.failure,
        errorMessage: _friendlySyncError(error.toString()),
      );
      if (!mounted) return;
      setState(() {
        _syncStatus = _KpiSyncStatus.failure;
        _lastResult = result;
      });
      await _recordSyncAttempt(result);
      if (!context.mounted) return;
      _showSyncSnackBar(context, result);
    }
  }

  Future<void> _recordSyncAttempt(_KpiSyncResult result) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .addAuditLog(
          switch (result.status) {
            _KpiSyncStatus.success => 'admin_sync_success',
            _KpiSyncStatus.partialSuccess => 'admin_sync_partial',
            _ => 'admin_sync_failed',
          },
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
          description: _syncResultMessage(result),
        );
  }

  void _showSyncSnackBar(BuildContext context, _KpiSyncResult result) {
    final color = switch (result.status) {
      _KpiSyncStatus.success => Colors.green,
      _KpiSyncStatus.partialSuccess => Colors.orange,
      _ => Colors.red,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(_syncResultMessage(result)),
      ),
    );
  }

  String _syncResultMessage(_KpiSyncResult result) {
    return switch (result.status) {
      _KpiSyncStatus.success =>
        'Synchronisation réussie. Toutes les modifications ont été enregistrées dans Firestore.\n'
            'Dernière synchronisation réussie : ${_formatDateTime(result.completedAt)}',
      _KpiSyncStatus.partialSuccess =>
        'Synchronisation partielle : ${result.successCount} modifications enregistrées, '
            '${result.failureCount} modification en échec.',
      _ =>
        'Échec de la synchronisation. Les modifications n’ont pas toutes été enregistrées.'
            '${result.errorMessage.isEmpty ? '' : '\n${result.errorMessage}'}',
    };
  }

  String _friendlySyncError(String error) {
    if (error.contains('permission-denied')) {
      return 'Accès refusé par les règles Firestore.';
    }
    if (error.contains('unauthenticated')) {
      return 'Utilisateur non authentifié.';
    }
    if (error.contains('unavailable') || error.contains('network')) {
      return 'Connexion Internet indisponible.';
    }
    if (error.contains('not-found')) return 'Document introuvable.';
    if (error.contains('conflict') || error.contains('version')) {
      return 'Conflit de données détecté.';
    }
    return 'Erreur inconnue lors de l’écriture dans Firestore.';
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }
}

class _SyncResultBanner extends StatelessWidget {
  const _SyncResultBanner({required this.result});

  final _KpiSyncResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.status) {
      _KpiSyncStatus.success => Colors.green,
      _KpiSyncStatus.partialSuccess => Colors.orange,
      _ => Colors.red,
    };
    final icon = switch (result.status) {
      _KpiSyncStatus.success => Icons.check_circle_outline,
      _KpiSyncStatus.partialSuccess => Icons.sync_problem_outlined,
      _ => Icons.error_outline,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(switch (result.status) {
              _KpiSyncStatus.success =>
                'Synchronisation réussie. Toutes les modifications ont été enregistrées dans Firestore.\n'
                    'Dernière synchronisation réussie : ${_formatBannerDate(result.completedAt)}',
              _KpiSyncStatus.partialSuccess =>
                'Synchronisation partielle : ${result.successCount} modifications enregistrées, '
                    '${result.failureCount} modification en échec.',
              _ =>
                'Échec de la synchronisation. Les modifications n’ont pas toutes été enregistrées.'
                    '${result.errorMessage.isEmpty ? '' : '\n${result.errorMessage}'}',
            }),
          ),
        ],
      ),
    );
  }

  static String _formatBannerDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }
}

class _DiagnosticCenterSection extends ConsumerStatefulWidget {
  const _DiagnosticCenterSection({required this.data});

  final FamilyTreeData data;

  @override
  ConsumerState<_DiagnosticCenterSection> createState() =>
      _DiagnosticCenterSectionState();
}

class _DiagnosticCenterSectionState
    extends ConsumerState<_DiagnosticCenterSection> {
  DiagnosticReport? _report;
  bool _testing = false;
  bool _testingFirestore = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final incidents = _incidents(widget.data);
    final lastError = incidents.isEmpty ? null : incidents.last;
    final errorCount = incidents.length;
    final report = _report;
    final busy = _testing || _testingFirestore;
    final hasReport = report?.hasResults == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centre de diagnostic',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : () => _runDiagnostic(),
                      icon: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fact_check_outlined),
                      label: const Text('Tester'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _runFirestoreDiagnostic(),
                      icon: _testingFirestore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.storage_outlined),
                      label: const Text('Tester Firestore'),
                    ),
                    OutlinedButton.icon(
                      onPressed: !hasReport || busy
                          ? null
                          : () => _copyReport(),
                      icon: const Icon(Icons.content_copy_outlined),
                      label: const Text('Copier le diagnostic'),
                    ),
                    OutlinedButton.icon(
                      onPressed: !hasReport || busy
                          ? null
                          : () => _exportReport(),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Export TXT'),
                    ),
                  ],
                ),
                if (auth.firebaseUid == null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Session Firebase non connectée'),
                      subtitle: const Text(
                        'Les tests Firestore nécessitent une connexion Firebase Admin réelle.',
                      ),
                      trailing: FilledButton.icon(
                        onPressed: busy ? null : _showFirebaseAdminLogin,
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('Se connecter comme administrateur'),
                      ),
                    ),
                  ),
                ],
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Diagnostic en cours...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 720;
                    final tiles = [
                      _DiagnosticStatusTile(
                        label: 'Etat Firestore',
                        value: report?.firestoreStatus ?? '-',
                        ok: report == null
                            ? null
                            : report.firestoreStatus == 'OK',
                      ),
                      _DiagnosticStatusTile(
                        label: 'Etat Firebase Authentication',
                        value: report?.authStatus ?? '-',
                        ok: report == null ? null : report.authStatus == 'OK',
                      ),
                      _DiagnosticStatusTile(
                        label: 'Etat Synchronisation',
                        value: report?.syncStatus ?? '$errorCount erreur(s)',
                        ok: report == null ? null : report.failedSyncCount == 0,
                      ),
                      _DiagnosticStatusTile(
                        label: 'Etat Réseau',
                        value: report?.networkStatus ?? '-',
                        ok: report == null
                            ? null
                            : report.networkStatus == 'OK',
                      ),
                      _DiagnosticStatusTile(
                        label: 'Etat Base locale',
                        value: report?.localDatabaseStatus ?? '-',
                        ok: report == null
                            ? null
                            : report.localDatabaseStatus == 'OK',
                      ),
                      _DiagnosticStatusTile(
                        label: 'Nombre d’erreurs',
                        value: errorCount.toString(),
                        ok: errorCount == 0,
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: compact ? 1 : 3,
                      childAspectRatio: compact ? 5.8 : 3.8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: tiles,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Dernière erreur',
                  value: lastError == null
                      ? '-'
                      : '${lastError.errorCode} sur ${lastError.collectionName}/${lastError.documentId}',
                ),
                if (report != null) ...[
                  _InfoRow(
                    label: 'Dernier diagnostic',
                    value: _formatDiagnosticDate(report.generatedAt),
                  ),
                  const SizedBox(height: 12),
                  _DiagnosticChecksList(checks: report.checks),
                  const Divider(height: 28),
                  _DiagnosticErrorsPreview(
                    errors: report.errors.take(8).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runDiagnostic() async {
    setState(() => _testing = true);
    try {
      final report = await ref
          .read(diagnosticServiceProvider)
          .run(data: widget.data, incidents: _incidents(widget.data));
      if (!mounted) return;
      setState(() => _report = report);
      _showSnackBar('Diagnostic terminé.');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _runFirestoreDiagnostic() async {
    setState(() => _testingFirestore = true);
    try {
      final report = await ref
          .read(diagnosticServiceProvider)
          .testFirestore(data: widget.data, incidents: _incidents(widget.data));
      if (!mounted) return;
      setState(() => _report = report);
      final failed = report.checks.where((check) => !check.ok).length;
      _showSnackBar(
        failed == 0
            ? 'Test Firestore terminé : lecture, écriture et suppression OK.'
            : 'Test Firestore terminé : $failed erreur(s).',
      );
    } finally {
      if (mounted) setState(() => _testingFirestore = false);
    }
  }

  Future<void> _copyReport() async {
    final report = _report;
    if (report == null) return;
    final content = ref.read(diagnosticServiceProvider).buildTextReport(report);
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    _showSnackBar('Diagnostic copié.');
  }

  Future<void> _showFirebaseAdminLogin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var loading = false;
    String? errorText;
    final signedIn = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Connexion administrateur Firebase'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    enabled: !loading,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                    enabled: !loading,
                    onSubmitted: (_) => _submitFirebaseAdminLogin(
                      context,
                      setDialogState,
                      emailController,
                      passwordController,
                      (value) => loading = value,
                      (value) => errorText = value,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
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
                onPressed: loading ? null : () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: loading
                    ? null
                    : () => _submitFirebaseAdminLogin(
                        context,
                        setDialogState,
                        emailController,
                        passwordController,
                        (value) => loading = value,
                        (value) => errorText = value,
                      ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_outlined),
                label: const Text('Se connecter'),
              ),
            ],
          );
        },
      ),
    );
    emailController.dispose();
    passwordController.dispose();
    if (signedIn == true && mounted) {
      _showSnackBar('Session Firebase connectée.');
    }
  }

  Future<void> _submitFirebaseAdminLogin(
    BuildContext dialogContext,
    StateSetter setDialogState,
    TextEditingController emailController,
    TextEditingController passwordController,
    ValueChanged<bool> setLoading,
    ValueChanged<String?> setError,
  ) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setDialogState(() => setError('E-mail et mot de passe requis.'));
      return;
    }
    setDialogState(() {
      setLoading(true);
      setError(null);
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .loginFirebaseAdmin(email: email, password: password);
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext, true);
    } catch (error) {
      setDialogState(() {
        setError(_friendlyFirebaseLoginError(error));
        setLoading(false);
      });
    }
  }

  String _friendlyFirebaseLoginError(Object error) {
    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Identifiants Firebase incorrects.';
    }
    if (message.contains('network-request-failed')) {
      return 'Connexion Internet indisponible.';
    }
    if (message.contains('rôle') || message.contains('droits')) {
      return message;
    }
    return 'Connexion Firebase impossible.';
  }

  Future<void> _exportReport() async {
    final report = _report;
    if (report == null) return;
    final content = ref.read(diagnosticServiceProvider).buildTextReport(report);
    await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter le diagnostic',
      fileName: _diagnosticFileName(report.generatedAt),
      bytes: utf8.encode(content),
    );
    if (!mounted) return;
    _showSnackBar('Diagnostic exporté.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<SyncIncident> _incidents(FamilyTreeData data) {
    return data.pendingSyncQueue
        .where((item) => item.status == 'failed' || item.lastError.isNotEmpty)
        .map(
          (item) =>
              SyncIncident.fromPendingItem(item, familyId: data.mainFamilyCode),
        )
        .toList();
  }

  String _diagnosticFileName(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return 'diagnostic_${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}.txt';
  }

  String _formatDiagnosticDate(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

class _DiagnosticStatusTile extends StatelessWidget {
  const _DiagnosticStatusTile({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = ok == null
        ? colorScheme.outline
        : ok!
        ? Colors.green.shade700
        : colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              ok == null
                  ? Icons.help_outline
                  : ok!
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, overflow: TextOverflow.ellipsis),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticChecksList extends StatelessWidget {
  const _DiagnosticChecksList({required this.checks});

  final List<DiagnosticCheck> checks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final check in checks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              check.ok ? Icons.check_circle_outline : Icons.error_outline,
              color: check.ok
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(check.label),
            subtitle: Text(
              [
                check.message,
                if (check.collectionName.isNotEmpty)
                  'Collection : ${check.collectionName}',
                if (check.documentPath.isNotEmpty)
                  'Document : ${check.documentPath}',
                if (check.ruleName.isNotEmpty) 'Règle : ${check.ruleName}',
                if (check.code.isNotEmpty) 'Code : ${check.code}',
              ].join('\n'),
            ),
            trailing: Text(
              check.responseTimeMs == null ? '-' : '${check.responseTimeMs} ms',
            ),
          ),
      ],
    );
  }
}

class _DiagnosticErrorsPreview extends StatelessWidget {
  const _DiagnosticErrorsPreview({required this.errors});

  final List<SyncIncident> errors;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.verified_outlined),
        title: Text('Dernières erreurs'),
        subtitle: Text('Aucune erreur enregistrée.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dernières erreurs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final error in errors)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(
              '${error.errorCode} - ${error.collectionName}/${error.documentId}',
            ),
            subtitle: Text(
              [
                error.lastOccurredAt,
                error.errorType,
                _errorSource(error),
                '${error.attemptCount} tentative(s)',
              ].where((value) => value.trim().isNotEmpty).join('\n'),
            ),
          ),
      ],
    );
  }

  String _errorSource(SyncIncident error) {
    final file = error.sourceFile.trim();
    final method = error.sourceFunction.trim();
    final line = error.sourceLine;
    if (file.isEmpty && method.isEmpty) return 'Localisation indisponible';
    final location = file.isEmpty
        ? ''
        : line == null
        ? file
        : '$file:$line';
    if (method.isEmpty) return location;
    if (location.isEmpty) return method;
    return '$method - $location';
  }
}

class _SyncIncidentsPanel extends ConsumerWidget {
  const _SyncIncidentsPanel({required this.incidents});

  final List<SyncIncident> incidents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newCount = incidents.where((item) => item.status == 'new').length;
    final inProgressCount = incidents
        .where((item) => item.status == 'inProgress')
        .length;
    final resolvedCount = incidents
        .where((item) => item.status == 'resolved')
        .length;
    final criticalCount = incidents
        .where((item) => item.severity == 'critical')
        .length;
    final lastIncident = incidents.isEmpty ? null : incidents.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Incidents de synchronisation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _IncidentChip(label: 'Nouveaux', value: newCount),
            _IncidentChip(label: 'En cours', value: inProgressCount),
            _IncidentChip(label: 'Résolus', value: resolvedCount),
            _IncidentChip(label: 'Critiques', value: criticalCount),
          ],
        ),
        if (lastIncident != null) ...[
          const SizedBox(height: 8),
          Text(
            'Dernière erreur : ${lastIncident.errorCode} sur '
            '${lastIncident.collectionName}/${lastIncident.documentId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (final incident in incidents)
                    _IncidentTile(
                      incident: incident,
                      onDetails: () => _showDetails(context, ref, incident),
                      onRetry: () => _retry(context, ref),
                      onInProgress: () =>
                          _mark(context, ref, incident, 'inProgress'),
                      onResolved: () =>
                          _mark(context, ref, incident, 'resolved'),
                      onCopy: () => _copy(context, incident),
                    ),
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Gravité')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Opération')),
                  DataColumn(label: Text('Ressource')),
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Tentatives')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: incidents
                    .map(
                      (incident) => DataRow(
                        cells: [
                          DataCell(Text(_shortDate(incident.lastOccurredAt))),
                          DataCell(Text(incident.severity)),
                          DataCell(Text(incident.errorType)),
                          DataCell(Text(incident.errorCode)),
                          DataCell(Text(incident.operationType)),
                          DataCell(
                            Text(
                              '${incident.collectionName}/${incident.documentId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(Text(_sourceLabel(incident))),
                          DataCell(Text(incident.attemptCount.toString())),
                          DataCell(Text(incident.status)),
                          DataCell(
                            _IncidentActions(
                              onDetails: () =>
                                  _showDetails(context, ref, incident),
                              onRetry: () => _retry(context, ref),
                              onInProgress: () =>
                                  _mark(context, ref, incident, 'inProgress'),
                              onResolved: () =>
                                  _mark(context, ref, incident, 'resolved'),
                              onCopy: () => _copy(context, incident),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    await ref.read(familyTreeProvider.notifier).syncPendingChanges();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouvelle tentative de synchronisation.')),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    WidgetRef ref,
    SyncIncident incident,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l’incident'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(_diagnosticText(incident, includeStack: false)),
                const SizedBox(height: 12),
                Text(
                  'Stack trace',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    incident.stackTrace.trim().isEmpty
                        ? 'Localisation indisponible dans cette version de production'
                        : incident.stackTrace,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _copyTrace(context, incident),
            icon: const Icon(Icons.content_copy_outlined),
            label: const Text('Copier la trace'),
          ),
          TextButton.icon(
            onPressed: () => _copy(context, incident),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Copier le diagnostic'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _retry(context, ref);
            },
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Réessayer'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mark(context, ref, incident, 'resolved');
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Résolu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    SyncIncident incident,
    String status,
  ) async {
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .updateSyncOperationStatus(
          incident.sourceOperationId,
          status: status,
          resolvedBy: auth.session?.familyCode ?? '',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Incident marqué $status.')));
  }

  Future<void> _copy(BuildContext context, SyncIncident incident) async {
    await Clipboard.setData(
      ClipboardData(text: _diagnosticText(incident, includeStack: true)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Diagnostic copié')));
  }

  Future<void> _copyTrace(BuildContext context, SyncIncident incident) async {
    await Clipboard.setData(ClipboardData(text: incident.stackTrace));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trace copiée')));
  }

  String _diagnosticText(SyncIncident incident, {required bool includeStack}) {
    return [
      'incident=${incident.id}',
      'date=${incident.lastOccurredAt}',
      'user=${_userLabel(incident)}',
      'familyId=${incident.familyId}',
      'operation=${incident.operationType}',
      'resource=${incident.collectionName}/${incident.documentId}',
      'errorType=${incident.errorType}',
      'errorCode=${incident.errorCode}',
      'safeMessage=${incident.safeMessage}',
      'technicalMessage=${incident.technicalMessage}',
      'source=${_sourceLabel(incident)}',
      'sourceFunction=${incident.sourceFunction}',
      'locationPrecision=${incident.locationPrecision}',
      'route=${incident.routeName}',
      'platform=${incident.platform}',
      'appVersion=${incident.appVersion}',
      'attempts=${incident.attemptCount}',
      'severity=${incident.severity}',
      'status=${incident.status}',
      'firstOccurredAt=${incident.firstOccurredAt}',
      'lastOccurredAt=${incident.lastOccurredAt}',
      if (includeStack) 'stackTrace=${incident.stackTrace}',
    ].join('\n');
  }

  String _sourceLabel(SyncIncident incident) {
    final function = incident.sourceFunction.trim();
    final file = incident.sourceFile.trim();
    if (file.isEmpty && function.isEmpty) return 'Localisation indisponible';
    final line = incident.sourceLine;
    final column = incident.sourceColumn;
    final location = file.isEmpty
        ? ''
        : line == null
        ? file
        : column == null
        ? '$file:$line'
        : '$file:$line:$column';
    if (function.isEmpty) return location;
    if (location.isEmpty) return function;
    return '$function - $location';
  }

  String _shortDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month ${hour}h$minute';
  }

  String _userLabel(SyncIncident incident) {
    if (incident.userEmail.trim().isNotEmpty) return incident.userEmail;
    if (incident.userId.trim().isNotEmpty) return incident.userId;
    return '-';
  }
}

class _ExternalNotificationsDisabledBanner extends StatelessWidget {
  const _ExternalNotificationsDisabledBanner({required this.settings});

  final AdminNotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.notifications_off_outlined),
              Text(
                'Notifications externes désactivées',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Chip(
                label: Text('Email: ${settings.emailEnabled ? 'on' : 'off'}'),
              ),
              const SizedBox(width: 6),
              Chip(
                label: Text(
                  'WhatsApp: ${settings.whatsappEnabled ? 'on' : 'off'}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentChip extends StatelessWidget {
  const _IncidentChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label : $value'));
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({
    required this.incident,
    required this.onDetails,
    required this.onRetry,
    required this.onInProgress,
    required this.onResolved,
    required this.onCopy,
  });

  final SyncIncident incident;
  final VoidCallback onDetails;
  final VoidCallback onRetry;
  final VoidCallback onInProgress;
  final VoidCallback onResolved;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final source = _sourceSummary(incident);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        incident.severity == 'critical'
            ? Icons.report_problem_outlined
            : Icons.sync_problem_outlined,
      ),
      title: Text('${incident.operationType} ${incident.collectionName}'),
      subtitle: Text(
        '${incident.documentId} - ${incident.errorCode} - '
        '$source - '
        '${incident.attemptCount} tentative(s)',
      ),
      trailing: _IncidentActions(
        onDetails: onDetails,
        onRetry: onRetry,
        onInProgress: onInProgress,
        onResolved: onResolved,
        onCopy: onCopy,
      ),
    );
  }

  String _sourceSummary(SyncIncident incident) {
    final function = incident.sourceFunction.trim();
    final file = incident.sourceFile.trim();
    if (file.isEmpty && function.isEmpty) return 'Localisation indisponible';
    final line = incident.sourceLine;
    final location = file.isEmpty
        ? ''
        : line == null
        ? file
        : '$file:$line';
    if (function.isEmpty) return location;
    if (location.isEmpty) return function;
    return '$function - $location';
  }
}

class _IncidentActions extends StatelessWidget {
  const _IncidentActions({
    required this.onDetails,
    required this.onRetry,
    required this.onInProgress,
    required this.onResolved,
    required this.onCopy,
  });

  final VoidCallback onDetails;
  final VoidCallback onRetry;
  final VoidCallback onInProgress;
  final VoidCallback onResolved;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          tooltip: 'Voir les détails',
          icon: const Icon(Icons.info_outline),
          onPressed: onDetails,
        ),
        IconButton(
          tooltip: 'Réessayer',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: onRetry,
        ),
        IconButton(
          tooltip: 'Marquer en cours',
          icon: const Icon(Icons.pending_actions_outlined),
          onPressed: onInProgress,
        ),
        IconButton(
          tooltip: 'Marquer résolu',
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onResolved,
        ),
        IconButton(
          tooltip: 'Copier le diagnostic',
          icon: const Icon(Icons.copy_outlined),
          onPressed: onCopy,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              if (compact) {
                return _buildCompactCodeList(
                  context,
                  l10n,
                  codes,
                  actorRole: actorRole,
                  adminId: adminId,
                );
              }
              return SingleChildScrollView(
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
                            DataCell(Text(_displayedCode(code))),
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
                              _buildCodeActions(
                                context,
                                l10n,
                                code,
                                actorRole: actorRole,
                                adminId: adminId,
                                compact: false,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCodeList(
    BuildContext context,
    AppLocalizations l10n,
    List<AccessCode> codes, {
    required String actorRole,
    required String adminId,
  }) {
    if (codes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.accessCodes),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final code in codes)
            _buildCompactCodeTile(
              context,
              l10n,
              code,
              actorRole: actorRole,
              adminId: adminId,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCodeTile(
    BuildContext context,
    AppLocalizations l10n,
    AccessCode code, {
    required String actorRole,
    required String adminId,
  }) {
    final visible = _visibleCodes.contains(code.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel(l10n, code.type),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            code.role,
                            code.enabled ? l10n.accepted : l10n.refused,
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _buildCodeActions(
                    context,
                    l10n,
                    code,
                    actorRole: actorRole,
                    adminId: adminId,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                visible ? code.code : '********',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: visible ? 0 : 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${l10n.codeUsage}: ${code.usedCount}/${code.maxUses ?? '∞'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${l10n.codeExpiration}: ${code.expiresAt.isEmpty ? '-' : _formatDate(code.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeActions(
    BuildContext context,
    AppLocalizations l10n,
    AccessCode code, {
    required String actorRole,
    required String adminId,
    required bool compact,
  }) {
    final accessCodeService = ref.watch(accessCodeServiceProvider);
    return Wrap(
      spacing: compact ? 0 : 2,
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
          onPressed: () => _showCodeDialog(context, code: code),
        ),
        if (!compact) ...[
          IconButton(
            tooltip: code.enabled
                ? l10n.disableAccessCode
                : l10n.enableAccessCode,
            icon: Icon(
              code.enabled ? Icons.block_outlined : Icons.check_circle_outline,
            ),
            onPressed: () => _setEnabled(code, !code.enabled),
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
        if (compact)
          PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (value) {
              switch (value) {
                case 'toggle':
                  _setEnabled(code, !code.enabled);
                  return;
                case 'delete':
                  _deleteCode(code);
                  return;
                case 'regenerate':
                  _regenerateCode(code);
                  return;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  code.enabled ? l10n.disableAccessCode : l10n.enableAccessCode,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.deleteAccessCode),
              ),
              PopupMenuItem(
                value: 'regenerate',
                enabled: accessCodeService.canRegenerate(
                  code,
                  actorRole: actorRole,
                  adminId: adminId,
                ),
                child: Text(l10n.regenerateCode),
              ),
            ],
          ),
      ],
    );
  }

  String _displayedCode(AccessCode code) =>
      _visibleCodes.contains(code.id) ? code.code : '********';

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
