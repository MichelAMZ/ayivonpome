import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/access_code.dart';
import '../models/family_honor.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/admin_access_service.dart';
import '../widgets/admin_contact_card.dart';
import '../widgets/kpi_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    final rotationStatus = ref
        .watch(adminAccessServiceProvider)
        .rotationStatus(data);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.adminKpi, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
            dataRole: auth.session?.role ?? 'viewer',
          ),
          const SizedBox(height: 24),
          const _FamilyHonorSection(),
          const SizedBox(height: 24),
          Text(
            l10n.manageAdmins,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
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
                TextField(
                  controller: oldController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.oldAdminCode),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.newAdminCode),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewAdminCode,
                    errorText: error,
                  ),
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

class _AccessCodeManagementSection extends ConsumerStatefulWidget {
  const _AccessCodeManagementSection({required this.dataRole});

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
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final codes = ref
        .watch(accessCodeServiceProvider)
        .visibleCodes(data, auth.session?.role ?? 'viewer');

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
                  TextField(
                    controller: value,
                    decoration: InputDecoration(
                      labelText: l10n.accessCodes,
                      errorText: error,
                    ),
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
  const _FamilyHonorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final honor = data.familyHonor;
    final selected = honor.patriarchPersonId.isEmpty
        ? null
        : data.people
              .where((person) => person.id == honor.patriarchPersonId)
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
