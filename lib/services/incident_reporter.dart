import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sync_diagnostic.dart';
import '../models/sync_incident.dart';
import '../models/sync_state.dart';
import 'family_repository.dart';

class IncidentReporter {
  const IncidentReporter(this._repository);

  static const _maxStackTraceLength = 12000;

  final FamilyRepository _repository;

  Future<void> report({
    required PendingSyncItem item,
    required String familyId,
    required Object error,
    required StackTrace stackTrace,
    String userId = '',
    String userEmail = '',
    String sourceFunction = '',
    String routeName = '',
  }) async {
    try {
      final incident = buildIncident(
        item: item,
        familyId: familyId,
        error: error,
        stackTrace: stackTrace,
        userId: userId,
        userEmail: userEmail,
        sourceFunction: sourceFunction,
        routeName: routeName,
      );
      await _repository.upsertSyncIncident(incident);
    } catch (reportError, reportStackTrace) {
      debugPrint('SYNC INCIDENT REPORT SKIPPED: $reportError');
      debugPrintStack(stackTrace: reportStackTrace);
    }
  }

  static SyncIncident buildIncident({
    required PendingSyncItem item,
    required String familyId,
    required Object error,
    required StackTrace stackTrace,
    String userId = '',
    String userEmail = '',
    String sourceFunction = '',
    String routeName = '',
  }) {
    final diagnostic = SyncOperationDiagnostic.fromItem(
      item,
      fallbackFamilyId: familyId,
      firebaseException: error is FirebaseException ? error : null,
    );
    final sanitizedMessage = sanitizeTechnicalData(error.toString());
    final sanitizedStackTrace = _truncateStackTrace(
      sanitizeTechnicalData(stackTrace.toString()),
    );
    final location = extractSourceLocation(stackTrace);
    final errorCode = _errorCode(error, item.lastError);
    final severity = errorCode == 'permission-denied' || item.retryCount >= 3
        ? 'critical'
        : 'warning';
    final now = DateTime.now().toIso8601String();
    final id = [
      diagnostic.familyId,
      diagnostic.collection,
      diagnostic.documentId,
      diagnostic.action,
      errorCode,
    ].map(_sanitizeIdPart).join('_');

    return SyncIncident(
      id: id,
      familyId: diagnostic.familyId,
      userId: userId,
      userEmail: userEmail,
      operationType: diagnostic.action,
      collectionName: diagnostic.collection,
      documentId: diagnostic.documentId,
      errorType: error.runtimeType.toString(),
      errorCode: errorCode,
      safeMessage: _safeMessage(errorCode),
      technicalMessage: sanitizedMessage,
      stackTrace: sanitizedStackTrace,
      sourceFile: location.sourceFile,
      sourceFunction: location.sourceFunction.isEmpty
          ? sourceFunction
          : location.sourceFunction,
      sourceLine: location.sourceLine,
      sourceColumn: location.sourceColumn,
      routeName: routeName,
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      locationPrecision: location.precision,
      attemptCount: item.retryCount + 1,
      firstOccurredAt: item.createdAt.isEmpty ? now : item.createdAt,
      lastOccurredAt: item.updatedAt.isEmpty ? now : item.updatedAt,
      status: switch (item.status) {
        'inProgress' => 'inProgress',
        'resolved' => 'resolved',
        _ => 'new',
      },
      severity: severity,
      sourceOperationId: item.id,
    );
  }

  static IncidentSourceLocation extractSourceLocation(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || _isInternalStackLine(line)) continue;
      final parsed = _parseStackLine(line);
      if (parsed != null) return parsed;
    }
    return const IncidentSourceLocation(precision: 'unavailable');
  }

  static String sanitizeTechnicalData(String value) {
    var sanitized = value;
    final patterns = <RegExp>[
      RegExp(
        r'(password|mot\s*de\s*passe|familyCode|codeFamilial|accessCode|apiKey|token|authorization|cookie)\s*[:=]\s*[^,\s}]+',
        caseSensitive: false,
      ),
      RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false),
      RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'),
      RegExp(r'\+?\d[\d\s().-]{7,}\d'),
    ];
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        final text = match.group(0) ?? '';
        final separatorIndex = text.indexOf(RegExp(r'[:=]'));
        if (separatorIndex == -1) return '[masque]';
        return '${text.substring(0, separatorIndex + 1)} [masque]';
      });
    }
    return sanitized;
  }

  static IncidentSourceLocation? _parseStackLine(String line) {
    final parenthesized = RegExp(
      r'\(([^()]+):([0-9]+):([0-9]+)\)',
    ).firstMatch(line);
    if (parenthesized != null) {
      final functionName = line
          .substring(0, parenthesized.start)
          .replaceFirst(RegExp(r'^#\d+\s+'), '')
          .trim();
      return IncidentSourceLocation(
        sourceFunction: functionName,
        sourceFile: _normalizeSourceFile(parenthesized.group(1) ?? ''),
        sourceLine: int.tryParse(parenthesized.group(2) ?? ''),
        sourceColumn: int.tryParse(parenthesized.group(3) ?? ''),
        precision: 'exact',
      );
    }

    final direct = RegExp(r'(.+?):(\d+):(\d+)').firstMatch(line);
    if (direct == null) return null;
    return IncidentSourceLocation(
      sourceFile: _normalizeSourceFile(direct.group(1) ?? ''),
      sourceLine: int.tryParse(direct.group(2) ?? ''),
      sourceColumn: int.tryParse(direct.group(3) ?? ''),
      precision: 'exact',
    );
  }

  static String _normalizeSourceFile(String value) {
    if (value.startsWith('package:ayivonpome/')) {
      return 'lib/${value.substring('package:ayivonpome/'.length)}';
    }
    final libIndex = value.indexOf('/lib/');
    if (libIndex != -1) return value.substring(libIndex + 1);
    final windowsLibIndex = value.indexOf(r'\lib\');
    if (windowsLibIndex != -1) {
      return value.substring(windowsLibIndex + 1).replaceAll(r'\', '/');
    }
    return value;
  }

  static bool _isInternalStackLine(String line) {
    return line.contains('(dart:') ||
        line.startsWith('dart:') ||
        line.contains('package:flutter/') ||
        line.contains('package:firebase_') ||
        line.contains('package:cloud_firestore/') ||
        line.contains('package:flutter_riverpod/');
  }

  static String _truncateStackTrace(String value) {
    if (value.length <= _maxStackTraceLength) return value;
    return '${value.substring(0, _maxStackTraceLength)}\n...[trace tronquée]';
  }

  static String _errorCode(Object error, String fallback) {
    if (error is FirebaseException) return error.code;
    if (fallback.contains('permission-denied')) return 'permission-denied';
    if (fallback.contains('unauthenticated')) return 'unauthenticated';
    if (fallback.contains('unavailable')) return 'unavailable';
    if (fallback.contains('failed-precondition')) return 'failed-precondition';
    if (fallback.contains('not-found')) return 'not-found';
    return 'sync-error';
  }

  static String _safeMessage(String errorCode) {
    return switch (errorCode) {
      'permission-denied' => 'Accès refusé par les règles Firestore.',
      'unauthenticated' => 'Utilisateur non authentifié.',
      'unavailable' => 'Connexion Internet indisponible.',
      'not-found' => 'Document introuvable.',
      'failed-precondition' => 'Précondition Firestore non respectée.',
      _ => 'Echec de synchronisation.',
    };
  }

  static String _sanitizeIdPart(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]+'),
      '-',
    );
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}

class IncidentSourceLocation {
  const IncidentSourceLocation({
    this.sourceFile = '',
    this.sourceFunction = '',
    this.sourceLine,
    this.sourceColumn,
    this.precision = 'unavailable',
  });

  final String sourceFile;
  final String sourceFunction;
  final int? sourceLine;
  final int? sourceColumn;
  final String precision;
}
