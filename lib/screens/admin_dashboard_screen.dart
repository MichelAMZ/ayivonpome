import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/access_code.dart';
import '../models/family_announcement.dart';
import '../models/family_honor.dart';
import '../models/family_leadership.dart';
import '../models/family_tree_data.dart';
import '../models/info_news.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/admin_access_service.dart';
import '../widgets/admin_contact_card.dart';
import '../widgets/kpi_card.dart';

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
    Future.microtask(
      () => ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const _InfoNewsManagementSection(),
          const SizedBox(height: 24),
          const _FamilyAnnouncementSection(),
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

class _InfoNewsManagementSection extends ConsumerStatefulWidget {
  const _InfoNewsManagementSection();

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
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final canManage = auth.isAdmin;
    final logs = data.infoNewsSendLogs
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
        for (final news in data.infoNews)
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
            '${l10n.historiesKept}: ${data.infoNewsSendLogs.length} · '
            '${l10n.lastCleanup}: ${_formatCleanupDate(data.infoNewsSendHistoryLastCleanedAt)}',
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
    final data = ref.read(familyTreeProvider).value!;
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
    final data = ref.read(familyTreeProvider).value!;
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
  const _FamilyAnnouncementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value!;
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
    final accessCodeService = ref.watch(accessCodeServiceProvider);
    final actorRole = auth.session?.role ?? 'viewer';
    final adminId = auth.session?.familyCode ?? '';
    final codes = accessCodeService.visibleCodes(data, actorRole);

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
  const _FamilyHonorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
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
