import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class FamilyHistoryButton extends StatelessWidget {
  const FamilyHistoryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Tooltip(
      message: l10n.ourHistory,
      child: compact
          ? IconButton(
              onPressed: onPressed,
              icon: const Icon(Icons.menu_book_outlined),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.ourHistory),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}
