import 'package:flutter/material.dart';

import 'responsive.dart';

class TopbarFamilyLogo extends StatelessWidget {
  const TopbarFamilyLogo({
    super.key,
    required this.membersCount,
    this.showCounter = true,
  });

  final int membersCount;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = width <= ResponsiveBreakpoints.mobileMax
        ? 64.0
        : width <= ResponsiveBreakpoints.tabletMax
        ? 100.0
        : 140.0;

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: logoSize,
            height: logoSize,
            child: Padding(
              padding: EdgeInsets.all(logoSize * 0.02),
              child: Image.asset(
                'assets/images/family_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (showCounter)
            Positioned(
              top: -8,
              child: _MemberCountBadge(
                count: membersCount,
                compact: width <= ResponsiveBreakpoints.mobileMax,
                large: width > ResponsiveBreakpoints.tabletMax,
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCountBadge extends StatelessWidget {
  const _MemberCountBadge({
    required this.count,
    required this.compact,
    required this.large,
  });

  final int count;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3C65B), width: 1),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x1A000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF4F6F1F),
          fontSize: compact
              ? 12
              : large
              ? 28
              : 18,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
