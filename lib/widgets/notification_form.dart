import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_notification.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';

class NotificationForm extends ConsumerStatefulWidget {
  const NotificationForm({super.key, required this.people, this.initialPerson});

  final List<Person> people;
  final Person? initialPerson;

  @override
  ConsumerState<NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends ConsumerState<NotificationForm> {
  late String _targetPersonId;
  var _type = 'customMessage';
  var _channel = 'local';
  late final TextEditingController _title;
  late final TextEditingController _message;
  late final TextEditingController _scheduledDate;

  Person get _target =>
      widget.people.firstWhere((person) => person.id == _targetPersonId);

  @override
  void initState() {
    super.initState();
    _targetPersonId = widget.initialPerson?.id ?? widget.people.first.id;
    _title = TextEditingController();
    _message = TextEditingController();
    _scheduledDate = TextEditingController(
      text: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _scheduledDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    if (!auth.isAdmin) {
      return AlertDialog(
        title: Text(l10n.notifications),
        content: Text(l10n.notificationAdminOnly),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      );
    }
    final availableChannels = _channelsFor(_target);
    if (!availableChannels.contains(_channel)) {
      _channel = availableChannels.first;
    }
    return AlertDialog(
      title: Text(l10n.notifyPerson),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _targetPersonId,
                decoration: InputDecoration(labelText: l10n.personDetails),
                items: widget.people
                    .map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _targetPersonId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.customMessage),
                items: [
                  DropdownMenuItem(
                    value: 'birthday',
                    child: Text(l10n.birthdayReminder),
                  ),
                  DropdownMenuItem(
                    value: 'deathAnniversary',
                    child: Text(l10n.deathAnniversaryReminder),
                  ),
                  DropdownMenuItem(
                    value: 'familyMeeting',
                    child: Text(l10n.familyMeetingReminder),
                  ),
                  DropdownMenuItem(
                    value: 'linkRequest',
                    child: Text(l10n.linkRequestReminder),
                  ),
                  DropdownMenuItem(
                    value: 'customMessage',
                    child: Text(l10n.customMessage),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _channel,
                decoration: InputDecoration(
                  labelText: l10n.notificationChannel,
                ),
                items: availableChannels
                    .map(
                      (channel) => DropdownMenuItem(
                        value: channel,
                        child: Text(_channelLabel(l10n, channel)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _channel = value ?? _channel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: l10n.notifications),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.customMessage),
              ),
              if (_channel == 'local') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _scheduledDate,
                  decoration: InputDecoration(
                    labelText: l10n.scheduleReminder,
                    helperText: DateTime.now().toIso8601String(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.notificationExternalAppNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(l10n.sendNotification),
        ),
      ],
    );
  }

  List<String> _channelsFor(Person person) {
    final channels = <String>['local', 'copy', 'futurePush'];
    if (person.email.trim().isNotEmpty && person.allowContact) {
      channels.insert(1, 'email');
    }
    if (person.whatsappNumber.trim().isNotEmpty && person.allowContact) {
      channels.insert(1, 'whatsapp');
    }
    return channels;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authSessionProvider);
    if (!auth.isAdmin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.notificationAdminOnly)));
      return;
    }
    final title = _title.text.trim().isEmpty
        ? l10n.notifications
        : _title.text.trim();
    final message = _message.text.trim().isEmpty
        ? '${l10n.notifyPerson}: ${_target.fullName}'
        : _message.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.sendNotification),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    var status = 'sent';
    try {
      switch (_channel) {
        case 'email':
          await ref
              .read(communicationServiceProvider)
              .sendEmail(email: _target.email, subject: title, body: message);
        case 'whatsapp':
          await ref
              .read(communicationServiceProvider)
              .openWhatsApp(
                phoneNumber: _target.whatsappNumber,
                message: message,
              );
        case 'local':
          status = 'pending';
          await ref
              .read(notificationServiceProvider)
              .scheduleLocalReminder(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                title: title,
                message: message,
                scheduledDate:
                    DateTime.tryParse(_scheduledDate.text.trim()) ??
                    DateTime.now(),
              );
        case 'copy':
          await ref.read(communicationServiceProvider).copyText(message);
        case 'futurePush':
          await ref
              .read(pushNotificationProvider)
              .sendPushNotification(
                targetUserId: _target.id,
                title: title,
                message: message,
              );
      }
    } catch (_) {
      status = 'failed';
    }

    final notification = FamilyNotification(
      id: 'n${DateTime.now().microsecondsSinceEpoch}',
      personId: widget.initialPerson?.id ?? '',
      targetPersonId: _target.id,
      type: _type,
      channel: _channel,
      title: title,
      message: message,
      scheduledDate: _channel == 'local' ? _scheduledDate.text.trim() : '',
      status: status,
      createdAt: DateTime.now().toIso8601String(),
    );
    await ref
        .read(familyTreeProvider.notifier)
        .upsertNotification(
          notification,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
          adminName: auth.session?.role ?? '',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'failed'
              ? l10n.notificationFailed
              : _channel == 'local'
              ? l10n.notificationScheduled
              : l10n.notificationSent,
        ),
      ),
    );
    Navigator.pop(context);
  }

  String _channelLabel(AppLocalizations l10n, String channel) =>
      switch (channel) {
        'local' => l10n.localNotification,
        'email' => l10n.emailNotification,
        'whatsapp' => l10n.whatsappNotification,
        'copy' => l10n.copy,
        'futurePush' => l10n.futurePushNotification,
        _ => channel,
      };
}
