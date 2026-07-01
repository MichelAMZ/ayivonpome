import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/app_settings.dart';
import 'package:ayivonpome/services/app_settings_service.dart';

void main() {
  test('AppSettings serializes tree view settings', () {
    const settings = AppSettings(
      applicationTitle: 'Famille AYIVON',
      treeSettings: TreeViewSettings(
        initialZoom: 0.60,
        minZoom: 0.40,
        maxZoom: 1.20,
        resetViewOnStartup: true,
        rememberLastZoom: false,
        rememberLastPosition: false,
        showMembersCounter: false,
      ),
      languageSettings: LanguageSettings(
        manualLocale: 'en',
        currentLocale: 'en',
      ),
      tutorialSettings: TutorialSettings(
        showTutorialOnFirstLaunch: false,
        tutorialAlreadySeen: true,
        showFloatingHelpButton: false,
      ),
    );

    final parsed = AppSettings.fromJson(settings.toJson());

    expect(parsed.treeSettings.initialZoom, 0.60);
    expect(parsed.treeSettings.minZoom, 0.40);
    expect(parsed.treeSettings.maxZoom, 1.20);
    expect(parsed.treeSettings.resetViewOnStartup, isTrue);
    expect(parsed.treeSettings.rememberLastZoom, isFalse);
    expect(parsed.treeSettings.rememberLastPosition, isFalse);
    expect(parsed.treeSettings.showMembersCounter, isFalse);
    expect(parsed.languageSettings.manualLocale, 'en');
    expect(parsed.languageSettings.currentLocale, 'en');
    expect(parsed.languageSettings.supportedLocales, [
      'fr',
      'en',
      'es',
      'pt',
      'de',
    ]);
    expect(parsed.tutorialSettings.showTutorialOnFirstLaunch, isFalse);
    expect(parsed.tutorialSettings.tutorialAlreadySeen, isTrue);
    expect(parsed.tutorialSettings.showFloatingHelpButton, isFalse);
    expect(parsed.tutorialSettings.buttonPosition, 'bottomRight');
  });

  test('AppSettingsService clamps invalid tree zoom values', () {
    const service = AppSettingsService();
    const settings = AppSettings(
      treeSettings: TreeViewSettings(
        initialZoom: 8.00,
        minZoom: 0.01,
        maxZoom: 9.00,
      ),
    );

    final normalized = service.normalize(settings);

    expect(normalized.treeSettings.minZoom, 0.40);
    expect(normalized.treeSettings.maxZoom, 1.20);
    expect(normalized.treeSettings.initialZoom, 1.20);
  });
}
