import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_runtime_config.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap({
    FirebaseRuntimeConfig config = const FirebaseRuntimeConfig(
      enabled: false,
      familyId: 'ayivon',
      trustedDevice: false,
    ),
  }) : _config = config;

  final FirebaseRuntimeConfig _config;

  Future<FirebaseApp?> initialize() async {
    if (!_config.enabled) return null;

    final app = Firebase.apps.isNotEmpty
        ? Firebase.app()
        : await Firebase.initializeApp(options: _config.options);

    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: _config.trustedDevice,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await _tryAnonymousSignIn();

    return app;
  }

  Future<void> _tryAnonymousSignIn() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (error, stackTrace) {
      debugPrint('Anonymous Firebase sign-in skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
