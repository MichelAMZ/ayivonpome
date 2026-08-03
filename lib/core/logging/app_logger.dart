import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'browser_environment.dart';

enum BootstrapStep {
  bindingInitialization,
  firebaseInitialization,
  localStorageInitialization,
  localeResolution,
  publicFamilyLoading,
  appReady,
}

class AppIncident {
  const AppIncident({
    required this.id,
    required this.category,
    required this.step,
    required this.errorType,
    required this.safeMessage,
    required this.safeStackTrace,
    required this.createdAt,
  });

  final String id;
  final String category;
  final BootstrapStep step;
  final String errorType;
  final String safeMessage;
  final String safeStackTrace;
  final DateTime createdAt;

  String technicalSummary() {
    final dispatcher = PlatformDispatcher.instance;
    final platformLocale = dispatcher.locale;
    final locales = dispatcher.locales
        .map((locale) => locale.toLanguageTag())
        .join(', ');
    final country = platformLocale.countryCode?.trim();
    final firebaseInitialized = Firebase.apps.isNotEmpty;
    final browser = readBrowserEnvironment();
    final view = dispatcher.views.firstOrNull;
    final logicalSize = view == null
        ? 'Indisponible'
        : '${(view.physicalSize.width / view.devicePixelRatio).round()} × '
              '${(view.physicalSize.height / view.devicePixelRatio).round()}';
    final source = _sourceLocation(safeStackTrace);
    var firebaseProject = 'Indisponible';
    var authState = 'Indisponible';
    if (firebaseInitialized) {
      try {
        firebaseProject = Firebase.app().options.projectId;
        final user = FirebaseAuth.instance.currentUser;
        authState = user == null ? 'Non connecté' : 'Connecté';
      } catch (_) {
        authState = 'Indisponible';
      }
    }
    return [
      'AYIVON DIAGNOSTIC',
      '',
      'Incident: $id',
      'Date UTC: ${createdAt.toUtc().toIso8601String()}',
      'Version: 1.0.0+1',
      'Build: release=$kReleaseMode',
      'Catégorie: $category',
      'Fonctionnalité: ${category == 'widget_rendering' ? 'rendu UI' : category}',
      'Étape: ${step.name}',
      'Route: ${_safeRoute(browser['url'])}',
      'Méthode: ${source.$1}',
      'Fichier: ${source.$2}',
      'Ligne: ${source.$3}',
      'Type: $errorType',
      'Message: $safeMessage',
      'Plateforme: ${defaultTargetPlatform.name}',
      'Navigateur: ${browser['browser'] ?? 'Indisponible'}',
      'UserAgent: ${browser['userAgent'] ?? 'Indisponible'}',
      'Dimensions écran: $logicalSize',
      'URL: ${browser['url'] ?? 'Indisponible'}',
      'Locale navigateur: ${platformLocale.toLanguageTag()}',
      'Langues navigateur: ${locales.isEmpty ? 'Indisponible' : locales}',
      'Pays: ${country == null || country.isEmpty ? 'Indéterminé' : country}',
      'Fuseau horaire: ${DateTime.now().timeZoneName}',
      'Firebase: ${firebaseInitialized ? 'Initialisé' : 'Indisponible'}',
      'Projet Firebase: $firebaseProject',
      'Authentification: $authState',
      'Mode release: $kReleaseMode',
      'Pile:',
      safeStackTrace.isEmpty ? 'Indisponible' : safeStackTrace,
    ].join('\n');
  }

  static String _safeRoute(String? url) {
    if (url == null || url.isEmpty || url == 'Indisponible') {
      return 'Indisponible';
    }
    try {
      final uri = Uri.parse(url);
      return uri.hasFragment && uri.fragment.isNotEmpty
          ? '#${uri.fragment}'
          : uri.path.isEmpty
          ? '/'
          : uri.path;
    } catch (_) {
      return 'Indisponible';
    }
  }

  static (String, String, String) _sourceLocation(String stack) {
    for (final line in stack.split('\n')) {
      final match = RegExp(
        r'([A-Za-z0-9_<>.$]+).*?([^\s()]+\.dart):(\d+)(?::\d+)?',
      ).firstMatch(line);
      if (match != null) {
        return (match.group(1)!, match.group(2)!, match.group(3)!);
      }
    }
    return ('Indisponible', 'Indisponible', 'Indisponible');
  }
}

class AppInitializationFailure implements Exception {
  const AppInitializationFailure(this.incident);

  final AppIncident incident;

  @override
  String toString() => 'Échec d’initialisation (${incident.id})';
}

class AppLogger {
  const AppLogger._();

  static BootstrapStep currentStep = BootstrapStep.bindingInitialization;
  static AppIncident? _lastIncident;
  static String? _lastIncidentSignature;

  static void startStep(BootstrapStep step) {
    currentStep = step;
    info('Bootstrap step started: ${step.name}');
  }

  static void completeStep(BootstrapStep step) {
    info('Bootstrap step completed: ${step.name}');
  }

  static AppIncident capture({
    required String category,
    required Object error,
    StackTrace? stackTrace,
    BootstrapStep? step,
  }) {
    final incidentStep = step ?? currentStep;
    final signature = '$category|${incidentStep.name}|$error';
    if (_lastIncidentSignature == signature && _lastIncident != null) {
      return _lastIncident!;
    }
    final now = DateTime.now();
    final suffix = now.microsecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase()
        .padLeft(4, '0');
    final incident = AppIncident(
      id:
          'AYV-${category == 'widget_rendering' ? 'UI' : 'BOOT'}-'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${suffix.substring(suffix.length - 4)}',
      category: category,
      step: incidentStep,
      errorType: error.runtimeType.toString(),
      safeMessage: _sanitize('$error'),
      safeStackTrace: _sanitizeStackTrace(stackTrace),
      createdAt: now,
    );
    _lastIncident = incident;
    _lastIncidentSignature = signature;
    developer.log(
      'Incident ${incident.id}: $category at ${incidentStep.name}',
      name: 'ayivon',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    return incident;
  }

  static String _sanitize(String value) {
    var result = value
        .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '<email>')
        .replaceAll(
          RegExp(
            r'(token|password|secret|code)\s*[:=]\s*\S+',
            caseSensitive: false,
          ),
          r'$1=<masqué>',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (result.length > 300) result = '${result.substring(0, 300)}…';
    return result;
  }

  static String _sanitizeStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    var result = '$stackTrace'
        .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '<email>')
        .replaceAll(RegExp(r'https?://\S+'), '<url>')
        .replaceAll(
          RegExp(
            r'(token|password|secret|code)\s*[:=]\s*\S+',
            caseSensitive: false,
          ),
          r'$1=<masqué>',
        )
        .trim();
    if (result.length > 2400) {
      result = '${result.substring(0, 2400)}…';
    }
    return result;
  }

  static void info(String message) {
    developer.log(message, name: 'ayivon');
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ayivon',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ayivon',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void presentFrameworkError(FlutterErrorDetails details) {
    capture(
      category: 'flutter_framework',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (!kReleaseMode) FlutterError.presentError(details);
  }
}
