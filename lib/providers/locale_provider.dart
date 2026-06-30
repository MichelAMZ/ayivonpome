import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';
import 'family_tree_provider.dart';

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  static const _selectedLocaleKey = 'selectedLocale';

  var _detecting = false;
  var _loadingPersistedLocale = false;
  var _manualSelectionVersion = 0;
  Locale? _cachedLocale;

  @override
  Locale? build() {
    final data = ref.watch(familyTreeProvider).value;
    if (data == null) {
      _loadPersistedLocaleIfNeeded();
      return _cachedLocale;
    }

    final settings = data.appSettings.languageSettings;
    final manualLocale = _supported(settings.manualLocale);
    if (manualLocale != null) {
      final locale = Locale(manualLocale);
      _cachedLocale = locale;
      debugPrint('LocaleProvider updated: $locale');
      return locale;
    }

    _loadPersistedLocaleIfNeeded();

    if (settings.autoDetectByCountry && !_detecting) {
      _detecting = true;
      final detectionVersion = _manualSelectionVersion;
      Future.microtask(() => _detectAndApply(detectionVersion));
    }

    final currentLocale = _supported(settings.currentLocale);
    if (currentLocale != null) {
      final locale = Locale(currentLocale);
      _cachedLocale = locale;
      debugPrint('LocaleProvider updated: $locale');
      return locale;
    }

    final legacyLocale = _supported(data.language);
    final locale = Locale(legacyLocale ?? 'fr');
    _cachedLocale = locale;
    debugPrint('LocaleProvider updated: $locale');
    return locale;
  }

  Future<void> setLocale(String languageCode) async {
    final locale = _supported(languageCode) ?? 'fr';
    _manualSelectionVersion++;
    _cachedLocale = Locale(locale);
    state = _cachedLocale;
    debugPrint('Language selected: $locale');
    debugPrint('LocaleProvider updated: $state');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLocaleKey, locale);
    await ref.read(familyTreeProvider.notifier).setLanguage(locale);
  }

  Future<void> _loadPersistedLocaleIfNeeded() async {
    if (_loadingPersistedLocale) return;
    _loadingPersistedLocale = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedLocale = _supported(
        prefs.getString(_selectedLocaleKey) ?? '',
      );
      if (persistedLocale == null) return;
      final data = ref.read(familyTreeProvider).value;
      final manualLocale = data == null
          ? null
          : _supported(data.appSettings.languageSettings.manualLocale);
      if (manualLocale != null) return;
      _cachedLocale = Locale(persistedLocale);
      state = _cachedLocale;
      debugPrint('LocaleProvider updated: $state');
      if (data != null) {
        await ref
            .read(familyTreeProvider.notifier)
            .setLanguage(persistedLocale);
      }
    } finally {
      _loadingPersistedLocale = false;
    }
  }

  Future<void> _detectAndApply(int detectionVersion) async {
    try {
      final detected = await ref
          .read(languageDetectionServiceProvider)
          .detectLocale();
      if (detectionVersion != _manualSelectionVersion) return;
      final data = ref.read(familyTreeProvider).value;
      final manualLocale = data == null
          ? null
          : _supported(data.appSettings.languageSettings.manualLocale);
      if (manualLocale != null) return;
      final prefs = await SharedPreferences.getInstance();
      if (_supported(prefs.getString(_selectedLocaleKey) ?? '') != null) {
        return;
      }
      final locale = _supported(detected) ?? 'fr';
      _cachedLocale = Locale(locale);
      state = _cachedLocale;
      debugPrint('LocaleProvider updated: $state');
      await ref
          .read(familyTreeProvider.notifier)
          .setLanguage(locale, manual: false);
    } finally {
      _detecting = false;
    }
  }

  String? _supported(String value) {
    final locale = value.trim().toLowerCase();
    if (const {'fr', 'en', 'es', 'pt', 'de'}.contains(locale)) return locale;
    return null;
  }
}
