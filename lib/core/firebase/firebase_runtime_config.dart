import 'package:firebase_core/firebase_core.dart';

import '../../config/app_environment.dart';
import '../../firebase_options_prod.dart';
import '../../firebase_options_staging.dart';

class FirebaseRuntimeConfig {
  static const FirebaseOptions defaultOptions = firebaseOptionsProd;

  const FirebaseRuntimeConfig({
    required this.enabled,
    required this.familyId,
    required this.trustedDevice,
    this.options,
  });

  factory FirebaseRuntimeConfig.fromEnvironment() {
    final environment = AppEnvironment.fromEnvironment();
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

    final hasInlineOptions =
        apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty;

    return FirebaseRuntimeConfig(
      enabled:
          const bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: true) &&
          !const bool.fromEnvironment('DISABLE_FIREBASE'),
      familyId: const String.fromEnvironment(
        'FIREBASE_FAMILY_ID',
        defaultValue: 'ayivon',
      ),
      trustedDevice: const bool.fromEnvironment('FIREBASE_TRUSTED_DEVICE'),
      options: environment.isStaging
          ? firebaseOptionsStagingFromEnvironment()
          : hasInlineOptions
          ? const FirebaseOptions(
              apiKey: apiKey,
              appId: appId,
              messagingSenderId: messagingSenderId,
              projectId: projectId,
              authDomain: authDomain,
              storageBucket: storageBucket,
            )
          : defaultOptions,
    );
  }

  final bool enabled;
  final String familyId;
  final bool trustedDevice;
  final FirebaseOptions? options;

  static const bool serverOperationQueueEnabled = bool.fromEnvironment(
    'SERVER_OPERATION_QUEUE_ENABLED',
  );
}
