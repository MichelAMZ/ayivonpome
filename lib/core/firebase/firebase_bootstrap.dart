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
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    return app;
  }
}
