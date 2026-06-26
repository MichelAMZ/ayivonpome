import 'package:flutter/material.dart';

import '../models/modification_history.dart';

class ModificationHistoryCard extends StatelessWidget {
  const ModificationHistoryCard({super.key, required this.item});

  final ModificationHistory item;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.modifiedAt);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(_iconFor(item.action)),
        ),
        title: Text(
          item.personFullName.isEmpty
              ? 'Personne inconnue'
              : item.personFullName,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_labelFor(item.action)} - ${item.modifiedByName}'),
            if (item.details.isNotEmpty) Text(item.details),
          ],
        ),
        trailing: date == null
            ? null
            : Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
      ),
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
      'person_added' => 'Personne ajoutée',
      'person_updated' => 'Personne modifiée',
      'person_deleted' => 'Personne supprimée',
      'relationship_added' => 'Lien familial ajouté',
      'relationship_updated' => 'Lien familial modifié',
      'family_link_accepted' => 'Lien familial accepté',
      'family_link_refused' => 'Lien familial refusé',
      'modification_code_used' => 'Code de modification utilisé',
      'admin_action' => 'Action admin',
      _ => action,
    };
  }
}
