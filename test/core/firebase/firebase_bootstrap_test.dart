import 'dart:io';

import 'package:ayivonpome/core/firebase/firebase_bootstrap.dart';
import 'package:ayivonpome/core/firebase/firebase_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled Firebase bootstrap is idempotent and degraded', () async {
    const bootstrap = FirebaseBootstrap(
      config: FirebaseRuntimeConfig(
        enabled: false,
        familyId: 'ayivon',
        trustedDevice: false,
      ),
    );

    final first = await bootstrap.initialize();
    final second = await bootstrap.initialize();

    expect(first, isNull);
    expect(second, isNull);
    expect(FirebaseBootstrap.status, FirebaseBootstrapStatus.degraded);
  });

  test('web bootstrap disables Firestore persistent cache', () {
    final source = File(
      'lib/core/firebase/firebase_bootstrap.dart',
    ).readAsStringSync();

    expect(source, contains('kIsWeb'));
    expect(source, contains('Settings(persistenceEnabled: false)'));
  });
}
