import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider)?.languageCode ?? l10n.localeName;
    final current = _supported(locale);
    return PopupMenuButton<String>(
      tooltip: l10n.chooseLanguage,
      onSelected: (language) {
        debugPrint('Language selected: $language');
        ref.read(localeProvider.notifier).setLocale(language);
      },
      itemBuilder: (context) => [
        _item(context, 'fr', l10n.french, current),
        _item(context, 'en', l10n.english, current),
        _item(context, 'es', l10n.spanish, current),
        _item(context, 'pt', l10n.portuguese, current),
        _item(context, 'de', l10n.german, current),
      ],
      child: compact ? _compactChild(current) : _fullChild(context, current),
    );
  }

  PopupMenuItem<String> _item(
    BuildContext context,
    String code,
    String label,
    String current,
  ) {
    final selected = current == code;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _compactChild(String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌐'),
          const SizedBox(width: 4),
          Text(code.toUpperCase()),
        ],
      ),
    );
  }

  Widget _fullChild(BuildContext context, String code) {
    return Tooltip(
      message: AppLocalizations.of(context).chooseLanguage,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          color: Colors.white.withValues(alpha: 0.72),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌐'),
              const SizedBox(width: 8),
              Text(
                code.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _supported(String code) {
    final value = code.toLowerCase();
    if (const {'fr', 'en', 'es', 'pt', 'de'}.contains(value)) return value;
    return 'fr';
  }
}
