import 'package:flutter/material.dart';

class ContactActionButton extends StatelessWidget {
  const ContactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
