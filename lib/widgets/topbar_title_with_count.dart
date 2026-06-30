import 'package:flutter/material.dart';

class TopBarTitleWithCount extends StatelessWidget {
  const TopBarTitleWithCount({
    super.key,
    required this.title,
    required this.membersCount,
    this.titleStyle,
    this.superscriptStyle,
    this.maxLines = 1,
  });

  final String title;
  final int membersCount;
  final TextStyle? titleStyle;
  final TextStyle? superscriptStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        titleStyle ??
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ) ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w800);
    final baseFontSize = baseStyle.fontSize ?? 22;
    final countStyle =
        superscriptStyle ??
        baseStyle.copyWith(
          color: const Color(0xFF6B7F2A),
          fontSize: baseFontSize * 0.58,
          fontWeight: FontWeight.w700,
          height: 1,
        );

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: title, style: baseStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                membersCount.toString(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: countStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
