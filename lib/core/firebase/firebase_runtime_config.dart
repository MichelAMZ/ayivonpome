import 'package:firebase_core/firebase_core.dart';

class FirebaseRuntimeConfig {
  static const FirebaseOptions defaultOptions = FirebaseOptions(
    apiKey: 'AIzaSyCTtBe2RhML26Fs0nd-cZ5aS_U6sorBH4I',
    appId: '1:487156596777:web:8d1043776dcfb6e6b75c38',
    messagingSenderId: '487156596777',
    projectId: 'ayivon-aziangbede',
    authDomain: 'ayivon-aziangbede.firebaseapp.com',
    storageBucket: 'ayivon-aziangbede.firebasestorage.app',
  );

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
      enabled:
          const bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: true) &&
          !const bool.fromEnvironment('DISABLE_FIREBASE'),
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
          : defaultOptions,
    );
  }

  final bool enabled;
  final String familyId;
  final bool trustedDevice;
  final FirebaseOptions? options;
}
