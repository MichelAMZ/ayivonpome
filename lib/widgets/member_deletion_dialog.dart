import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import 'modification_code_required_dialog.dart';

class MemberDeletionDialog extends ConsumerStatefulWidget {
  const MemberDeletionDialog({
    required this.person,
    required this.data,
    required this.onDelete,
    this.showUnlockDialog,
    super.key,
  });

  final Person person;
  final FamilyTreeData data;
  final Future<void> Function() onDelete;
  final Future<bool?> Function(BuildContext context)? showUnlockDialog;

  @override
  ConsumerState<MemberDeletionDialog> createState() =>
      _MemberDeletionDialogState();
}

class _MemberDeletionDialogState extends ConsumerState<MemberDeletionDialog> {
  final _confirmationController = TextEditingController();
  bool _deleting = false;
  bool _unlocking = false;
  bool _resumingAfterUnlock = false;
  bool _isAuthorizationPopupOpen = false;
  String? _error;
  String? _authorizationMessage;

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

  bool get _memberExists =>
      widget.data.people.any((person) => person.id == widget.person.id);

  String get _familyId => widget.person.familyCode.isEmpty
      ? widget.data.mainFamilyCode
      : widget.person.familyCode;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final authorized = auth.canDeleteFamily(_familyId);
    final deleteDisabledReason = !_memberExists
        ? 'Ce membre n’existe plus dans l’arbre. Fermez cette boîte et actualisez la page.'
        : !authorized
        ? 'Déverrouillez d’abord l’administration.'
        : !_isConfirmed
        ? 'Saisissez le nom complet du membre ou SUPPRIMER.'
        : null;
    return AlertDialog(
      title: const Text('Supprimer ce membre ?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action supprimera le membre de la famille et peut affecter ses relations familiales.',
              ),
              const SizedBox(height: 16),
              Text('Membre : ${widget.person.fullName}'),
              Text('Famille ou branche : $_familyId'),
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
              const SizedBox(height: 14),
              if (!authorized)
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: 'Autorisation administrateur requise',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autorisation administrateur requise',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'La suppression d’un membre nécessite une session Firebase administrateur active.\n\n'
                          '1. Cliquez sur « Déverrouiller l’administration ».\n'
                          '2. Saisissez votre code administrateur.\n'
                          '3. Revenez confirmer la suppression.',
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message:
                              'Ouvrir la saisie du code administrateur sans quitter cette suppression.',
                          child: FilledButton.icon(
                            onPressed:
                                _deleting || _unlocking || _resumingAfterUnlock
                                ? null
                                : _unlockAdministration,
                            icon: _unlocking
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.key_outlined),
                            label: const Text('Déverrouiller l’administration'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_authorizationMessage != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _authorizationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (deleteDisabledReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  deleteDisabledReason,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting
              ? null
              : () {
                  Navigator.pop(context, false);
                },
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: !_isConfirmed || !authorized || !_memberExists || _deleting
              ? null
              : _delete,
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever),
          label: Text(
            _deleting
                ? 'Suppression et enregistrement…'
                : 'Supprimer et enregistrer',
          ),
        ),
      ],
    );
  }

  Future<void> _delete() async {
    if (_deleting ||
        !_isConfirmed ||
        !_memberExists ||
        !ref.read(authSessionProvider).canDeleteFamily(_familyId)) {
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final authorizationFailure = _isAuthorizationFailure(error);
      setState(() {
        _deleting = false;
        if (authorizationFailure) {
          _authorizationMessage = null;
        }
        _error = _messageFor(error);
      });
    }
  }

  Future<void> _unlockAdministration() async {
    if (_unlocking || _resumingAfterUnlock || _deleting) return;
    var retryRequested = false;
    setState(() {
      _unlocking = true;
      _error = null;
      _authorizationMessage = null;
    });
    try {
      final unlocked =
          await (widget.showUnlockDialog?.call(context) ??
              showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => const ModificationCodeRequiredDialog(
                  requiredMode: ModificationAuthorizationMode.administration,
                ),
              ));
      if (!mounted || unlocked != true) return;
      setState(() {
        _resumingAfterUnlock = true;
        _authorizationMessage =
            'Vérification de l’autorisation administrateur…';
      });
      final authorized = await ref
          .read(authSessionProvider.notifier)
          .refreshEffectiveAdminAuthorization(familyId: _familyId);
      if (!mounted) return;
      setState(() {
        _authorizationMessage = authorized
            ? 'Administration déverrouillée. Vous pouvez maintenant confirmer la suppression.'
            : 'La session est ouverte, mais ce compte ne possède pas les droits nécessaires pour supprimer ce membre.';
      });
      if (!authorized) {
        retryRequested = await _showInsufficientAuthorizationPopup();
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
          _resumingAfterUnlock = false;
        });
      }
    }
    if (retryRequested && mounted) {
      await _unlockAdministration();
    }
  }

  Future<bool> _showInsufficientAuthorizationPopup() async {
    if (_isAuthorizationPopupOpen || !mounted) return false;
    _isAuthorizationPopupOpen = true;
    try {
      final unlock = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const _InsufficientAuthorizationDialog(),
      );
      return unlock == true;
    } finally {
      _isAuthorizationPopupOpen = false;
    }
  }

  bool _isAuthorizationFailure(Object error) {
    final message = '$error'.toLowerCase();
    return message.contains('permission-denied') ||
        message.contains('unauthenticated');
  }

  String _messageFor(Object error) {
    final message = '$error'.toLowerCase();
    if (message.contains('family_leader_replacement_required')) {
      return 'Désignez d’abord un nouveau chef de famille.';
    }
    if (_isAuthorizationFailure(error)) {
      return 'La session est ouverte, mais les règles Firestore n’autorisent pas cette opération. Vérifiez le rôle administrateur et la famille associée.';
    }
    if (message.contains('unavailable') ||
        message.contains('network') ||
        message.contains('connexion')) {
      return 'La suppression nécessite une connexion sécurisée à Firebase. Réessayez lorsque la connexion sera disponible.';
    }
    return 'La suppression n’a pas été confirmée par Firebase. Le membre a été conservé.';
  }
}

class _InsufficientAuthorizationDialog extends StatelessWidget {
  const _InsufficientAuthorizationDialog();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC58A17);
    return AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.admin_panel_settings_outlined, color: accent),
      ),
      title: const Text(
        'Autorisation administrateur requise',
        textAlign: TextAlign.center,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.32)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La session est ouverte, mais ce compte ne possède pas les droits nécessaires pour supprimer ce membre.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                'Déverrouillez l’administration avec un code administrateur valide, puis revenez confirmer la suppression.',
              ),
            ],
          ),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.key_outlined),
          label: const Text('Déverrouiller l’administration'),
        ),
      ],
    );
  }
}
