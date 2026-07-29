import 'dart:ui';

class LanguageDetectionService {
  const LanguageDetectionService();

  static const supportedLocales = ['fr', 'en', 'es', 'pt', 'de'];

  Future<String> detectLocale() async {
    final locales = PlatformDispatcher.instance.locales;
    for (final locale in locales) {
      final countryCode = locale.countryCode;
      final byCountry = countryCode == null
          ? null
          : localeForCountry(countryCode);
      if (byCountry != null) return byCountry;

      final byLanguage = localeForLanguage(locale.languageCode);
      if (byLanguage != null) return byLanguage;
    }
    return 'fr';
  }

  String? localeForLanguage(String languageCode) {
    final value = languageCode.toLowerCase();
    return supportedLocales.contains(value) ? value : null;
  }

  String normalizeCountryCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.length != 2) return 'UNKNOWN';
    return normalized;
  }

  String? localeForCountry(String? countryCode) {
    final country = normalizeCountryCode(countryCode);
    if (const {
      'FR',
      'TG',
      'BJ',
      'CI',
      'CD',
      'CG',
      'CM',
      'SN',
      'ML',
      'BF',
      'NE',
      'GN',
      'HT',
    }.contains(country)) {
      return 'fr';
    }
    if (country == 'CA') return 'fr';
    if (const {'GB', 'US', 'GH', 'NG', 'IE', 'AU', 'NZ'}.contains(country)) {
      return 'en';
    }
    if (country == 'ES') return 'es';
    if (const {'PT', 'BR'}.contains(country)) return 'pt';
    if (country == 'DE') return 'de';
    return null;
  }
}
