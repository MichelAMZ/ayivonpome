import 'package:firebase_core/firebase_core.dart';

FirebaseOptions firebaseOptionsStagingFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  if ([
    apiKey,
    appId,
    messagingSenderId,
    projectId,
  ].any((value) => value.isEmpty)) {
    throw StateError(
      'Les options Firebase staging explicites sont obligatoires.',
    );
  }
  return const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );
}
