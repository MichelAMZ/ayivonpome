import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';

class PersonOriginNameText extends StatelessWidget {
  const PersonOriginNameText({
    super.key,
    required this.person,
    this.maxLines = 1,
    this.fontSize,
    this.topPadding = 2,
  });

  final Person person;
  final int maxLines;
  final double? fontSize;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (!person.shouldShowOriginLastName) {
      return const SizedBox.shrink();
    }
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      letterSpacing: 0,
    );
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Text(
        '${AppLocalizations.of(context).nee} ${person.originLastName}',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }
}
