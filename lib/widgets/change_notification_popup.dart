import 'package:flutter/material.dart';

import '../models/change_notification.dart';

class ChangeNotificationPopup extends StatelessWidget {
  const ChangeNotificationPopup({
    super.key,
    required this.notifications,
    required this.onSeen,
    required this.onClose,
    required this.onDoNotShowAgain,
    required this.onViewHistory,
  });

  final List<ChangeNotification> notifications;
  final VoidCallback onSeen;
  final VoidCallback onClose;
  final VoidCallback onDoNotShowAgain;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final latest = notifications.take(6).toList();
    return AlertDialog(
      alignment: Alignment.bottomLeft,
      insetPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      title: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Dernières modifications')),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in latest)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: Icon(_iconFor(item.action), size: 18),
                ),
                title: Text(
                  item.personFullName.isEmpty
                      ? 'Personne inconnue'
                      : item.personFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_labelFor(item.action)} - ${item.modifiedByName}\n${_formatDate(item.modifiedAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (notifications.length > latest.length)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '+ ${notifications.length - latest.length} autres modifications',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDoNotShowAgain,
          child: const Text('Ne plus afficher'),
        ),
        TextButton(
          onPressed: onViewHistory,
          child: const Text('Voir l’historique complet'),
        ),
        TextButton(onPressed: onClose, child: const Text('Fermer')),
        FilledButton(onPressed: onSeen, child: const Text('J’ai vu')),
      ],
    );
  }

  IconData _iconFor(String action) {
    return switch (action) {
      'person_added' => Icons.person_add_alt_1,
      'person_updated' => Icons.edit_outlined,
      'person_deleted' => Icons.person_remove_outlined,
      'relationship_added' => Icons.account_tree_outlined,
      'family_link_accepted' => Icons.link,
      'family_link_refused' => Icons.link_off,
      'modification_code_used' => Icons.key_outlined,
      _ => Icons.history,
    };
  }

  String _labelFor(String action) {
    return switch (action) {
      'person_added' => 'Ajout',
      'person_updated' => 'Modification',
      'person_deleted' => 'Suppression',
      'relationship_added' => 'Lien familial',
      'relationship_updated' => 'Lien modifié',
      'family_link_accepted' => 'Lien accepté',
      'family_link_refused' => 'Lien refusé',
      'modification_code_used' => 'Code utilisé',
      _ => action,
    };
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
