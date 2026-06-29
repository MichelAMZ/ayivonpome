import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class SecureCodeTextField extends StatefulWidget {
  const SecureCodeTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SecureCodeTextField> createState() => _SecureCodeTextFieldState();
}

class _SecureCodeTextFieldState extends State<SecureCodeTextField> {
  var _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tooltip = _obscureText ? l10n.showCode : l10n.hideCode;
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: _obscureText,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: Tooltip(
          message: tooltip,
          child: IconButton(
            tooltip: tooltip,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            iconSize: 24,
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: widget.enabled
                ? () => setState(() => _obscureText = !_obscureText)
                : null,
          ),
        ),
      ),
    );
  }
}
