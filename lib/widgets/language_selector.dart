import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.language),
      items: [
        DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
        DropdownMenuItem(value: 'en', child: Text(l10n.english)),
        DropdownMenuItem(value: 'es', child: Text(l10n.spanish)),
        DropdownMenuItem(value: 'pt', child: Text(l10n.portuguese)),
        DropdownMenuItem(value: 'de', child: Text(l10n.german)),
      ],
      onChanged: (language) {
        if (language != null) {
          debugPrint('Language selected: $language');
          ref.read(localeProvider.notifier).setLocale(language);
        }
      },
    );
  }
}
