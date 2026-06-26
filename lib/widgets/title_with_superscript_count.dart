import 'package:flutter/material.dart';

class TitleWithSuperscriptCount extends StatelessWidget {
  const TitleWithSuperscriptCount({
    super.key,
    required this.title,
    required this.count,
    required this.semanticLabel,
  });

  final String title;
  final int count;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    return Semantics(
      label: '$title, $semanticLabel',
      child: RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(text: title),
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Transform.translate(
                  offset: const Offset(0, -5),
                  child: Text(
                    '$count',
                    textScaler: const TextScaler.linear(0.62),
                    style: style?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
