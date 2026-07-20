import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/member_save_result.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import 'admin_contact_card.dart';
import 'secure_code_text_field.dart';

enum ModificationAuthorizationStep {
  idle,
  preparingFirebase,
  verifyingCode,
  restoringAuthentication,
  checkingPermissions,
  savingToFirestore,
  synchronizing,
  saved,
  savedLocally,
  failed,
}

extension ModificationAuthorizationStepUi on ModificationAuthorizationStep {
  bool get isProcessing => switch (this) {
    ModificationAuthorizationStep.preparingFirebase ||
    ModificationAuthorizationStep.verifyingCode ||
    ModificationAuthorizationStep.restoringAuthentication ||
    ModificationAuthorizationStep.checkingPermissions ||
    ModificationAuthorizationStep.savingToFirestore ||
    ModificationAuthorizationStep.synchronizing => true,
    _ => false,
  };

  String get buttonLabel => switch (this) {
    ModificationAuthorizationStep.preparingFirebase =>
      'Préparation de Firebase…',
    ModificationAuthorizationStep.verifyingCode => 'Vérification du code…',
    ModificationAuthorizationStep.restoringAuthentication =>
      'Connexion sécurisée…',
    ModificationAuthorizationStep.checkingPermissions =>
      'Vérification des autorisations…',
    ModificationAuthorizationStep.savingToFirestore => 'Enregistrement…',
    ModificationAuthorizationStep.synchronizing => 'Synchronisation…',
    ModificationAuthorizationStep.saved => 'Code validé',
    ModificationAuthorizationStep.savedLocally => 'Sauvegardé localement',
    ModificationAuthorizationStep.failed => 'Réessayer',
    ModificationAuthorizationStep.idle => 'Vérifier et enregistrer',
  };

  String get statusLabel => switch (this) {
    ModificationAuthorizationStep.preparingFirebase =>
      'Préparation de la connexion sécurisée…',
    ModificationAuthorizationStep.verifyingCode =>
      'Vérification du code de modification…',
    ModificationAuthorizationStep.restoringAuthentication =>
      'Restauration de votre session…',
    ModificationAuthorizationStep.checkingPermissions =>
      'Vérification de vos autorisations…',
    ModificationAuthorizationStep.savingToFirestore =>
      'Enregistrement dans la base familiale…',
    ModificationAuthorizationStep.synchronizing =>
      'Synchronisation des modifications…',
    ModificationAuthorizationStep.saved =>
      'Code validé. Modifications enregistrées et synchronisées.',
    ModificationAuthorizationStep.savedLocally =>
      'Modifications sauvegardées sur cet appareil. Synchronisation en attente.',
    ModificationAuthorizationStep.failed =>
      'Code incorrect ou accès non autorisé.',
    ModificationAuthorizationStep.idle => '',
  };
}

class ModificationCodeRequiredDialog extends ConsumerStatefulWidget {
  const ModificationCodeRequiredDialog({
    this.operationIds = const [],
    super.key,
  });

  final List<String> operationIds;

  @override
  ConsumerState<ModificationCodeRequiredDialog> createState() =>
      _ModificationCodeRequiredDialogState();
}

class _ModificationCodeRequiredDialogState
    extends ConsumerState<ModificationCodeRequiredDialog> {
  static const _remoteTimeout = Duration(seconds: 20);
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  ModificationAuthorizationStep _step = ModificationAuthorizationStep.idle;
  String _preparationStatus = 'Préparation…';
  DateTime? _stepStartedAt;

  bool get _isProcessing => _step.isProcessing;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareFirebase());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value;
    final admins = data == null
        ? const []
        : ref.read(adminServiceProvider).activeAdmins(data);
    return AlertDialog(
      title: const Text('Autorisation requise'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vos modifications sont conservées sur cet appareil. '
                'Pour les envoyer dans la base familiale partagée, saisissez un code de modification valide.',
              ),
              const SizedBox(height: 12),
              ...admins.map((admin) => AdminContactCard(admin: admin)),
              const SizedBox(height: 12),
              SecureCodeTextField(
                controller: _controller,
                focusNode: _focusNode,
                label: l10n.enterModificationCode,
                errorText: _error,
                enabled: !_isProcessing,
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 10),
              _statusMessage(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            _isProcessing ? 'Continuer en arrière-plan' : l10n.cancel,
          ),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _unlock,
          child: AnimatedSwitcher(
            duration: _animationDuration(context),
            child: _isProcessing
                ? Row(
                    key: ValueKey(_step),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(_step.buttonLabel)),
                    ],
                  )
                : Text(
                    _step.buttonLabel,
                    key: const ValueKey('idle-modification-code-button'),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _unlock() async {
    if (_isProcessing) return;
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _step = ModificationAuthorizationStep.failed;
        _error = 'Saisissez le code de modification.';
      });
      _focusNode.requestFocus();
      return;
    }
    _setStep(ModificationAuthorizationStep.preparingFirebase);
    try {
      await _prepareFirebase();
      _setStep(ModificationAuthorizationStep.verifyingCode);
      final ok = await ref
          .read(authSessionProvider.notifier)
          .unlockModification(code)
          .timeout(_remoteTimeout);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _step = ModificationAuthorizationStep.failed;
          _error = 'Code incorrect ou accès non autorisé.';
        });
        _focusNode.requestFocus();
        return;
      }
      _setStep(ModificationAuthorizationStep.restoringAuthentication);
      final restored = await ref
          .read(authSessionProvider.notifier)
          .restoreSession()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (!restored) {
        setState(() {
          _step = ModificationAuthorizationStep.failed;
          _error = 'Session Firebase non restaurée ou accès non autorisé.';
        });
        return;
      }
      _setStep(ModificationAuthorizationStep.checkingPermissions);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      _setStep(ModificationAuthorizationStep.synchronizing);
      final result = await ref
          .read(familyTreeProvider.notifier)
          .retryOperationsById(widget.operationIds)
          .timeout(_remoteTimeout);
      if (!mounted) return;
      if (!result.isFirestoreConfirmed) {
        if (result.remoteStatus == RemoteSaveStatus.permissionRequired) {
          setState(() {
            _step = ModificationAuthorizationStep.failed;
            _error = 'Code incorrect ou accès Firebase non autorisé.';
          });
        } else {
          await _finishAsLocalPending(
            'Modifications sauvegardées sur cet appareil. Synchronisation en attente.',
          );
        }
        return;
      }
      _setStep(ModificationAuthorizationStep.saved);
      _controller.clear();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code validé. Modifications enregistrées et synchronisées.',
          ),
        ),
      );
    } on TimeoutException {
      await _finishAsLocalPending(
        'Firebase met plus de temps que prévu à répondre. Vos modifications sont sauvegardées sur cet appareil.',
      );
    } catch (error) {
      await _finishAsLocalPending(
        'Modifications sauvegardées sur cet appareil. Synchronisation en attente.',
      );
    }
  }

  Future<void> _finishAsLocalPending(String message) async {
    if (!mounted) return;
    setState(() {
      _step = ModificationAuthorizationStep.savedLocally;
      _error = message;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _prepareFirebase() async {
    if (mounted && !_isProcessing) {
      setState(() => _preparationStatus = 'Préparation…');
    }
    try {
      await ref
          .read(familyTreeProvider.future)
          .timeout(const Duration(seconds: 6));
      if (!mounted || _isProcessing) return;
      setState(() => _preparationStatus = 'Connexion prête');
    } catch (_) {
      if (!mounted || _isProcessing) return;
      setState(() => _preparationStatus = 'Mode hors ligne');
    }
  }

  Widget _statusMessage() {
    final status = _step == ModificationAuthorizationStep.idle
        ? _preparationStatus
        : _step.statusLabel;
    if (status.isEmpty) return const SizedBox.shrink();
    final isProblem =
        _step == ModificationAuthorizationStep.failed ||
        _step == ModificationAuthorizationStep.savedLocally;
    final color = isProblem
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF52606D);
    return Semantics(
      liveRegion: true,
      label: status,
      child: AnimatedSwitcher(
        duration: _animationDuration(context),
        child: Text(
          key: ValueKey(status),
          _isProcessing
              ? '$status\nVeuillez patienter, cette opération peut prendre quelques secondes.'
              : status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }

  void _setStep(ModificationAuthorizationStep step) {
    final now = DateTime.now();
    final previous = _step;
    final previousStartedAt = _stepStartedAt;
    if (previousStartedAt != null) {
      final elapsed = now.difference(previousStartedAt);
      debugPrint(
        'Modification authorization step ${previous.name} completed in ${elapsed.inMilliseconds}ms',
      );
    }
    debugPrint('Modification authorization step ${step.name} started');
    if (!mounted) return;
    setState(() {
      _step = step;
      _error = null;
      _stepStartedAt = now;
    });
  }

  Duration _animationDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);
}
