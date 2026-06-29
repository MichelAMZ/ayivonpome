import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class DivorceBadge extends StatelessWidget {
  const DivorceBadge({super.key, this.year = ''});

  final String year;

  @override
  Widget build(BuildContext context) {
    final label = year.isEmpty
        ? AppLocalizations.of(context).divorced
        : '${AppLocalizations.of(context).divorced} $year';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF4B8C0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '💔 $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF9A2636),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
