import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import 'notification_form.dart';

class NotifyPersonButton extends ConsumerWidget {
  const NotifyPersonButton({
    super.key,
    required this.person,
    required this.people,
  });

  final Person person;
  final List<Person> people;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    if (!auth.isAdmin) return const SizedBox.shrink();
    return FilledButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) =>
            NotificationForm(people: people, initialPerson: person),
      ),
      icon: const Icon(Icons.notifications_active_outlined),
      label: Text(l10n.notifyPerson),
    );
  }
}
