import 'package:flutter/material.dart';

class MobileTitleMemberCountBadge extends StatelessWidget {
  const MobileTitleMemberCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF5E6F1F),
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      height: 1,
    );

    return Semantics(
      label: '$count membres',
      child: Container(
        constraints: const BoxConstraints(minWidth: 28, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9EC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFC5D877), width: 1.2),
        ),
        child: Text(
          count.toString(),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}
