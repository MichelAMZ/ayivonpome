import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_runtime_config.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.completeStep(BootstrapStep.bindingInitialization);

  FlutterError.onError = AppLogger.presentFrameworkError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.capture(
      category: 'platform',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (details) {
      final incident = AppLogger.capture(
        category: 'widget_rendering',
        error: details.exception,
        stackTrace: details.stack,
      );
      return AppInlineError(incident: incident);
    };
  }

  final bootstrap = runZonedGuarded<Future<void>>(_bootstrapApplication, (
    error,
    stackTrace,
  ) {
    AppLogger.capture(
      category: 'application',
      error: error,
      stackTrace: stackTrace,
    );
  });
  if (bootstrap != null) await bootstrap;
}

Future<void> _bootstrapApplication() async {
  AppLogger.info('Application bootstrap started');
  AppLogger.startStep(BootstrapStep.firebaseInitialization);
  final firebaseInitialization = FirebaseBootstrap(
    config: FirebaseRuntimeConfig.fromEnvironment(),
  ).initialize();

  // La consultation publique repose sur les données embarquées et ne doit
  // jamais attendre un service distant avant d'afficher le premier écran.
  runApp(const ProviderScope(child: FamilyTreeApp()));

  try {
    await firebaseInitialization.timeout(const Duration(seconds: 4));
    AppLogger.completeStep(BootstrapStep.firebaseInitialization);
  } on TimeoutException catch (error, stackTrace) {
    AppLogger.warning(
      'Firebase bootstrap timed out; public app continues with bundled data',
      error: error,
      stackTrace: stackTrace,
    );
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Firebase bootstrap unavailable; continuing in degraded mode',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
