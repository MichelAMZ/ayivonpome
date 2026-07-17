import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_runtime_config.dart';

enum FirebaseBootstrapStatus { initializing, ready, degraded, failed }

class FirebaseBootstrap {
  const FirebaseBootstrap({
    FirebaseRuntimeConfig config = const FirebaseRuntimeConfig(
      enabled: false,
      familyId: 'ayivon',
      trustedDevice: false,
    ),
  }) : _config = config;

  final FirebaseRuntimeConfig _config;

  static Future<FirebaseApp?>? _initialization;
  static FirebaseBootstrapStatus _status = FirebaseBootstrapStatus.degraded;
  static Object? _lastError;

  static FirebaseBootstrapStatus get status => _status;
  static Object? get lastError => _lastError;

  Future<FirebaseApp?> initialize() async {
    if (!_config.enabled) {
      _status = FirebaseBootstrapStatus.degraded;
      return null;
    }
    final pending = _initialization;
    if (pending != null) return pending;

    _status = FirebaseBootstrapStatus.initializing;
    _initialization = _initializeOnce();
    return _initialization;
  }

  Future<FirebaseApp?> _initializeOnce() async {
    try {
      final app = Firebase.apps.isNotEmpty
          ? Firebase.app()
          : await Firebase.initializeApp(options: _config.options);

      final auth = FirebaseAuth.instanceFor(app: app);
      if (kIsWeb) {
        await auth.setPersistence(Persistence.LOCAL);
      }

      var degraded = false;
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } on FirebaseException catch (error) {
        degraded = true;
        _lastError = error;
        debugPrint(
          'Firestore persistence unavailable: ${error.code} ${error.message ?? ''}',
        );
      }

      _status = degraded
          ? FirebaseBootstrapStatus.degraded
          : FirebaseBootstrapStatus.ready;
      return app;
    } catch (error) {
      _status = FirebaseBootstrapStatus.failed;
      _lastError = error;
      _initialization = null;
      rethrow;
    }
  }
}
