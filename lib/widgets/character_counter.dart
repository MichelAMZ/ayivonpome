import 'package:flutter/material.dart';

class CharacterCounter extends StatelessWidget {
  const CharacterCounter({
    super.key,
    required this.count,
    required this.max,
    this.label,
  });

  final int count;
  final int max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final exceeded = count > max;
    final remaining = max - count;
    final color = exceeded
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF4D742B);
    return Text(
      label ?? '$count / $max caractères',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      semanticsLabel: '$remaining caractères restants',
    );
  }
}
