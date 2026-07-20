import 'package:flutter/material.dart';

import '../models/family_tree_data.dart';
import '../models/person.dart';

class MemberDeletionDialog extends StatefulWidget {
  const MemberDeletionDialog({
    required this.person,
    required this.data,
    required this.onDelete,
    super.key,
  });

  final Person person;
  final FamilyTreeData data;
  final Future<void> Function() onDelete;

  @override
  State<MemberDeletionDialog> createState() => _MemberDeletionDialogState();
}

class _MemberDeletionDialogState extends State<MemberDeletionDialog> {
  final _confirmationController = TextEditingController();
  bool _deleting = false;
  String? _error;

  bool get _isConfirmed {
    final value = _confirmationController.text.trim();
    return value.toUpperCase() == 'SUPPRIMER' ||
        value.toLowerCase() == widget.person.fullName.trim().toLowerCase();
  }

  int get _affectedRelations {
    final id = widget.person.id;
    final memberReferences = widget.data.people.where((person) {
      return person.id != id &&
          (person.fatherId == id ||
              person.motherId == id ||
              person.spouseIds.contains(id) ||
              person.childrenIds.contains(id) ||
              person.parents.contains(id) ||
              person.spouses.contains(id) ||
              person.children.contains(id));
    }).length;
    final unions = widget.data.marriageRelations
        .where((relation) => relation.involves(id))
        .length;
    return memberReferences + unions;
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer ce membre ?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action supprimera le membre de la famille et peut affecter ses relations familiales.',
            ),
            const SizedBox(height: 16),
            Text('Membre : ${widget.person.fullName}'),
            Text(
              'Famille ou branche : ${widget.person.familyCode.isEmpty ? widget.data.mainFamilyCode : widget.person.familyCode}',
            ),
            Text('Relations pouvant être affectées : $_affectedRelations'),
            const SizedBox(height: 16),
            const Text(
              'Saisissez le nom complet du membre ou SUPPRIMER pour confirmer.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmationController,
              enabled: !_deleting,
              autofocus: true,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Confirmation',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: !_isConfirmed || _deleting ? null : _delete,
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever),
          label: const Text('Supprimer définitivement'),
        ),
      ],
    );
  }

  Future<void> _delete() async {
    if (_deleting || !_isConfirmed) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = _messageFor(error);
      });
    }
  }

  String _messageFor(Object error) {
    final message = '$error'.toLowerCase();
    if (message.contains('family_leader_replacement_required')) {
      return 'Désignez d’abord un nouveau chef de famille.';
    }
    if (message.contains('permission-denied') ||
        message.contains('unauthenticated')) {
      return 'Une session Firebase administrateur autorisée est requise.';
    }
    if (message.contains('unavailable') ||
        message.contains('network') ||
        message.contains('connexion')) {
      return 'La suppression nécessite une connexion sécurisée à Firebase. Réessayez lorsque la connexion sera disponible.';
    }
    return 'La suppression n’a pas été confirmée par Firebase. Le membre a été conservé.';
  }
}
