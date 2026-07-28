import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/screens/settings_screen.dart').readAsStringSync();
  });

  test('settings center uses responsive premium sections', () {
    expect(source, contains('class _SettingsHeader'));
    expect(source, contains('class _SettingsGrid'));
    expect(source, contains('class _SettingsSectionCard'));
    expect(source, contains('constraints.maxWidth >= 1320'));
    expect(source, contains('constraints.maxWidth >= 760'));
    expect(source, contains('BorderRadius.circular(20)'));
    expect(source, contains('Rechercher un paramètre'));
  });

  test('existing settings actions remain connected', () {
    expect(source, contains('_setHistoryCleanupEnabled(ref, auth, value)'));
    expect(source, contains('_setDataCleanupSettings('));
    expect(source, contains('_confirmAndCleanOldHistory(context, ref, auth)'));
    expect(source, contains('_confirmAndRunDataCleanup(context, ref)'));
    expect(source, contains('authSessionProvider.notifier).logout()'));
    expect(
      source,
      contains("BugReportButton(initialScreen: 'SettingsScreen')"),
    );
    expect(source, contains('LanguageSelector(value: data.language)'));
  });

  test('switches expose semantics and mobile header avoids overflow', () {
    expect(source, contains('Semantics('));
    expect(source, contains('toggled: value'));
    expect(source, contains('constraints.maxWidth < 620'));
  });
}
