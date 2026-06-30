import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class MembersCounterBadge extends StatelessWidget {
  const MembersCounterBadge({
    super.key,
    required this.count,
    this.compact = false,
  });

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E8CB)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥'),
            const SizedBox(width: 7),
            Text(
              compact ? '$count' : l10n.membersCount(count),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF2F5D22),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
