import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'authorization badge is restricted to actual authorization failures',
    () {
      final source = File(
        'lib/widgets/sync_status_badge.dart',
      ).readAsStringSync();
      final classification = source.substring(
        source.indexOf('final storedAuthorizationFailures'),
        source.indexOf('final conflictCount'),
      );

      expect(classification, contains("'authorizationRequired'"));
      expect(classification, contains('hasEffectiveWriteAccess'));
      expect(classification, contains("'permission-denied'"));
      expect(classification, contains("'unauthenticated'"));
      expect(
        classification,
        isNot(contains("item.status == 'needsResolution'")),
      );
    },
  );
}
