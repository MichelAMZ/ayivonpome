import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_notification.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/notification_form.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      floatingActionButton: data.people.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => NotificationForm(people: data.people),
              ),
              icon: const Icon(Icons.add_alert_outlined),
              label: Text(l10n.sendNotification),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.noBackendPushNotice),
          const SizedBox(height: 12),
          _Group(
            title: l10n.pending,
            notifications: data.notifications
                .where((notification) => notification.status == 'pending')
                .toList(),
          ),
          _Group(
            title: l10n.accepted,
            notifications: data.notifications
                .where((notification) => notification.status == 'sent')
                .toList(),
          ),
          _Group(
            title: l10n.notificationFailed,
            notifications: data.notifications
                .where((notification) => notification.status == 'failed')
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.notifications});

  final String title;
  final List<FamilyNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (notifications.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none_outlined),
              title: Text(l10n.emptyState),
            ),
          )
        else
          ...notifications.map(
            (notification) => Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(notification.title),
                subtitle: Text(
                  [
                    notification.channel,
                    notification.type,
                    notification.scheduledDate,
                    notification.message,
                  ].where((item) => item.isNotEmpty).join('\n'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
