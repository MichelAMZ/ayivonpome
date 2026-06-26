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
      items: const [
        DropdownMenuItem(value: 'fr', child: Text('Français')),
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'es', child: Text('Español')),
        DropdownMenuItem(value: 'pt', child: Text('Português')),
        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
      ],
      onChanged: (language) {
        if (language != null) {
          ref.read(localeProvider.notifier).setLocale(language);
        }
      },
    );
  }
}
