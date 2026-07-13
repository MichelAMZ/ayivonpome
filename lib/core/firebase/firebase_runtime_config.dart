import 'package:firebase_core/firebase_core.dart';

class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig({
    required this.enabled,
    required this.familyId,
    required this.trustedDevice,
    this.options,
  });

  factory FirebaseRuntimeConfig.fromEnvironment() {
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
      enabled: const bool.fromEnvironment('ENABLE_FIREBASE'),
      familyId: const String.fromEnvironment(
        'FIREBASE_FAMILY_ID',
        defaultValue: 'ayivon',
      ),
      trustedDevice: const bool.fromEnvironment('FIREBASE_TRUSTED_DEVICE'),
      options: hasInlineOptions
          ? const FirebaseOptions(
              apiKey: apiKey,
              appId: appId,
              messagingSenderId: messagingSenderId,
              projectId: projectId,
              authDomain: authDomain,
              storageBucket: storageBucket,
            )
          : null,
    );
  }

  final bool enabled;
  final String familyId;
  final bool trustedDevice;
  final FirebaseOptions? options;
}
