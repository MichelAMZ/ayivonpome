import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class FamilyCouncilButton extends StatelessWidget {
  const FamilyCouncilButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Tooltip(
      message: l10n.viewCouncilMembers,
      child: compact
          ? IconButton(
              onPressed: onPressed,
              icon: const Icon(Icons.groups_2_outlined),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.groups_2_outlined),
              label: Text(l10n.familyCouncil),
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
