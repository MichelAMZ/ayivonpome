import '../models/app_settings.dart';

class AppSettingsService {
  const AppSettingsService();

  AppSettings normalize(AppSettings settings) {
    final title = settings.applicationTitle.trim();
    final subtitle = settings.applicationSubtitle.trim();
    final officialFamilyName = settings.officialFamilyName.trim();
    final treeSettings = settings.treeSettings;
    const minZoom = 0.40;
    const maxZoom = 1.20;
    final initialZoom = treeSettings.initialZoom
        .clamp(minZoom, maxZoom)
        .toDouble();
    final languageSettings = settings.languageSettings;
    final tutorialSettings = settings.tutorialSettings;
    final supportedLocales = languageSettings.supportedLocales
        .where(_isSupportedLocale)
        .toSet()
        .toList();
    final normalizedSupportedLocales = supportedLocales.isEmpty
        ? const ['fr', 'en', 'es', 'pt', 'de']
        : supportedLocales;
    final manualLocale = _normalizeLocale(
      languageSettings.manualLocale,
      normalizedSupportedLocales,
    );
    final currentLocale =
        _normalizeLocale(
          languageSettings.currentLocale,
          normalizedSupportedLocales,
        ) ??
        manualLocale;
    return settings.copyWith(
      applicationTitle: title.isEmpty ? 'FamilyTreeApp' : title,
      applicationSubtitle: subtitle,
      showApplicationSubtitle:
          settings.showApplicationSubtitle && subtitle.isNotEmpty,
      officialFamilyName: officialFamilyName,
      treeSettings: treeSettings.copyWith(
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
      languageSettings: languageSettings.copyWith(
        manualLocale: manualLocale ?? '',
        currentLocale: currentLocale ?? '',
        supportedLocales: normalizedSupportedLocales,
      ),
      tutorialSettings: tutorialSettings.copyWith(
        buttonPosition: tutorialSettings.buttonPosition == 'bottomRight'
            ? tutorialSettings.buttonPosition
            : 'bottomRight',
      ),
    );
  }

  bool _isSupportedLocale(String locale) {
    return const {'fr', 'en', 'es', 'pt', 'de'}.contains(locale);
  }

  String? _normalizeLocale(String locale, List<String> supportedLocales) {
    final value = locale.trim().toLowerCase();
    if (value.isEmpty || !supportedLocales.contains(value)) return null;
    return value;
  }
}
