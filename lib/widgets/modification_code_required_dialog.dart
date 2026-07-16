import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import 'admin_contact_card.dart';
import 'secure_code_text_field.dart';

class ModificationCodeRequiredDialog extends ConsumerStatefulWidget {
  const ModificationCodeRequiredDialog({super.key});

  @override
  ConsumerState<ModificationCodeRequiredDialog> createState() =>
      _ModificationCodeRequiredDialogState();
}

class _ModificationCodeRequiredDialogState
    extends ConsumerState<ModificationCodeRequiredDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final admins = ref.read(adminServiceProvider).activeAdmins(data);
    return AlertDialog(
      title: Text(l10n.modificationCodeRequired),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.modificationCodeRequiredMessage),
              const SizedBox(height: 12),
              ...admins.map((admin) => AdminContactCard(admin: admin)),
              const SizedBox(height: 12),
              SecureCodeTextField(
                controller: _controller,
                label: l10n.enterModificationCode,
                errorText: _error,
                onSubmitted: (_) => _unlock(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _unlock, child: Text(l10n.enter)),
      ],
    );
  }

  Future<void> _unlock() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(authSessionProvider.notifier)
        .unlockModification(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accès modification autorisé.')),
      );
    } else {
      setState(() => _error = l10n.invalidModificationCode);
    }
  }
}
