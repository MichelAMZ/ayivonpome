import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/services/language_detection_service.dart';

void main() {
  const service = LanguageDetectionService();

  test('maps countries to supported locales', () {
    expect(service.localeForCountry('FR'), 'fr');
    expect(service.localeForCountry('TG'), 'fr');
    expect(service.localeForCountry('BJ'), 'fr');
    expect(service.localeForCountry('CI'), 'fr');
    expect(service.localeForCountry('US'), 'en');
    expect(service.localeForCountry('GB'), 'en');
    expect(service.localeForCountry('GH'), 'en');
    expect(service.localeForCountry('NG'), 'en');
    expect(service.localeForCountry('ES'), 'es');
    expect(service.localeForCountry('PT'), 'pt');
    expect(service.localeForCountry('BR'), 'pt');
    expect(service.localeForCountry('DE'), 'de');
  });

  test('maps browser language to supported locales', () {
    expect(service.localeForLanguage('fr'), 'fr');
    expect(service.localeForLanguage('en'), 'en');
    expect(service.localeForLanguage('es'), 'es');
    expect(service.localeForLanguage('pt'), 'pt');
    expect(service.localeForLanguage('de'), 'de');
    expect(service.localeForLanguage('it'), isNull);
  });
}
