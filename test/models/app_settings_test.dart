import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/app_settings.dart';
import 'package:ayivonpome/models/branding_settings.dart';
import 'package:ayivonpome/services/app_settings_service.dart';

void main() {
  test('AppSettings serializes tree view settings', () {
    const settings = AppSettings(
      applicationTitle: 'Famille AYIVON',
      storageSettings: StorageSettings(
        mode: 'hybrid',
        localJsonEnabled: true,
        remoteDatabaseEnabled: true,
        offlineQueueEnabled: true,
        autoSyncOnReconnect: true,
        syncStatus: 'pending',
      ),
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
      branding: BrandingSettings(
        logoEnabled: false,
        logoUrl: 'https://example.com/logo.webp',
        logoFileName: 'logo.webp',
        logoMimeType: 'image/webp',
        logoWidthDesktop: 120,
        memberCountDisplayMode: 'superscriptTitle',
        useAsFavicon: true,
        logoVersion: 3,
      ),
    );

    final parsed = AppSettings.fromJson(settings.toJson());

    expect(parsed.treeSettings.initialZoom, 0.60);
    expect(parsed.storageSettings.mode, 'hybrid');
    expect(parsed.storageSettings.localJsonEnabled, isTrue);
    expect(parsed.storageSettings.remoteDatabaseEnabled, isTrue);
    expect(parsed.storageSettings.offlineQueueEnabled, isTrue);
    expect(parsed.storageSettings.autoSyncOnReconnect, isTrue);
    expect(parsed.storageSettings.syncStatus, 'pending');
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
    expect(parsed.branding.logoEnabled, isFalse);
    expect(parsed.branding.logoUrl, 'https://example.com/logo.webp');
    expect(parsed.branding.logoFileName, 'logo.webp');
    expect(parsed.branding.logoMimeType, 'image/webp');
    expect(parsed.branding.logoWidthDesktop, 120);
    expect(parsed.branding.memberCountDisplayMode, 'superscriptTitle');
    expect(parsed.branding.useAsFavicon, isTrue);
    expect(parsed.branding.logoVersion, 3);
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
