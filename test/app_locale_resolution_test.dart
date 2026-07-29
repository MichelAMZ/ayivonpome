import 'package:ayivonpome/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supportedLocales = [Locale('de'), Locale('en'), Locale('fr')];

  test('keeps every supported browser language regardless of region', () {
    final cases = {
      const Locale('fr', 'FR'): const Locale('fr'),
      const Locale('fr', 'CA'): const Locale('fr'),
      const Locale('de', 'DE'): const Locale('de'),
      const Locale('de', 'AT'): const Locale('de'),
      const Locale('en', 'US'): const Locale('en'),
      const Locale('en', 'GB'): const Locale('en'),
    };

    for (final entry in cases.entries) {
      expect(resolveAppLocale(entry.key, supportedLocales), entry.value);
    }
  });

  test('falls back to French for an unsupported browser locale', () {
    for (final locale in const [
      Locale('it', 'IT'),
      Locale('ar', 'SA'),
      Locale('zh', 'CN'),
      Locale('ja', 'JP'),
    ]) {
      expect(resolveAppLocale(locale, supportedLocales), const Locale('fr'));
    }
  });

  test('falls back to French when the browser locale is unavailable', () {
    expect(resolveAppLocale(null, supportedLocales), const Locale('fr'));
  });
}
