import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'secure_code_text_field.dart';

Future<bool> ensureCanViewMemberDetails(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(authSessionProvider).canViewMemberDetails) return true;

  final l10n = AppLocalizations.of(context);
  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ViewerAccessDialog(
      title: l10n.enterAccessCode,
      label: l10n.familyCode,
      invalidMessage: l10n.invalidCode,
      cancelLabel: l10n.cancel,
      submitLabel: l10n.enter,
      onValidate: (code) => ref.read(authSessionProvider.notifier).login(code),
    ),
  );

  return allowed == true && ref.read(authSessionProvider).canViewMemberDetails;
}

class _ViewerAccessDialog extends StatefulWidget {
  const _ViewerAccessDialog({
    required this.title,
    required this.label,
    required this.invalidMessage,
    required this.cancelLabel,
    required this.submitLabel,
    required this.onValidate,
  });

  final String title;
  final String label;
  final String invalidMessage;
  final String cancelLabel;
  final String submitLabel;
  final Future<bool> Function(String code) onValidate;

  @override
  State<_ViewerAccessDialog> createState() => _ViewerAccessDialogState();
}

class _ViewerAccessDialogState extends State<_ViewerAccessDialog> {
  final _controller = TextEditingController();
  String? _error;
  var _submitting = false;
  var _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncInputState);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncInputState);
    _controller.dispose();
    super.dispose();
  }

  void _syncInputState() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput == _hasInput) return;
    setState(() {
      _hasInput = hasInput;
      if (hasInput) _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SecureCodeTextField(
          controller: _controller,
          label: widget.label,
          autofocus: true,
          enabled: !_submitting,
          errorText: _error,
          onSubmitted: (_) {
            if (_hasInput) _submit();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submitting || !_hasInput ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_hasInput) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final valid = await widget.onValidate(_controller.text);
      if (!mounted) return;
      if (valid) {
        Navigator.pop(context, true);
        return;
      }
    } catch (_) {
      // The existing invalid-code message is used for every denied attempt.
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = widget.invalidMessage;
    });
  }
}
