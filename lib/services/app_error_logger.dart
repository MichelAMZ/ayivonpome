import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StackFrameInfo {
  const StackFrameInfo({
    this.methodName,
    this.sourceFile,
    this.sourceLine,
    this.sourceColumn,
  });

  final String? methodName;
  final String? sourceFile;
  final int? sourceLine;
  final int? sourceColumn;
}

/// Journal technique Firestore indépendant du flux CRUD et de toute file de
/// rejeu. Un échec du logger n'affecte jamais l'opération utilisateur.
class AppErrorLogger {
  AppErrorLogger({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required this.familyId,
    this.environment = 'development',
    this.appVersion = '1.0.0+1',
    DateTime Function()? now,
  }) : _firestore = firestore,
       _auth = auth,
       _now = now ?? DateTime.now;

  static const _deduplicationWindow = Duration(seconds: 15);
  static const _maxStackLines = 40;
  static const _maxStackLength = 8000;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String familyId;
  final String environment;
  final String appVersion;
  final DateTime Function() _now;
  final Map<String, DateTime> _lastCapturedAt = {};
  bool _isWriting = false;

  Future<void> capture({
    required Object error,
    required StackTrace stackTrace,
    required String feature,
    required String operation,
    required String entityType,
    String entityId = '',
    String role = '',
    String route = '',
    String severity = 'error',
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || _isWriting) return;
    final effectiveRole = role.trim().isEmpty
        ? await _readCurrentRole(user.uid)
        : role.trim();
    if (effectiveRole.isEmpty) return;

    final frame = parseRelevantStackFrame(stackTrace);
    final errorCode = error is FirebaseException ? error.code : '';
    final methodName = frame.methodName ?? '';
    final sourceFile = frame.sourceFile ?? '';
    final signature = [
      errorCode,
      methodName,
      sourceFile,
      frame.sourceLine ?? '',
      entityId,
    ].join('|');
    final now = _now();
    final previous = _lastCapturedAt[signature];
    if (previous != null && now.difference(previous) < _deduplicationWindow) {
      return;
    }
    _lastCapturedAt[signature] = now;
    _isWriting = true;
    try {
      final id = '${now.microsecondsSinceEpoch}_${_stableHash(signature)}';
      await _firestore.collection('app_error_logs').doc(id).set({
        'familyId': familyId,
        'environment': environment,
        'severity': severity,
        'feature': feature,
        'methodName': methodName,
        'sourceFile': sourceFile,
        'sourceLine': frame.sourceLine,
        'sourceColumn': frame.sourceColumn,
        'errorType': error.runtimeType.toString(),
        'errorCode': errorCode,
        'errorMessage': sanitizeErrorMessage(error.toString()),
        'stackTrace': sanitizeStackTrace(stackTrace.toString()),
        'operation': operation,
        'entityType': entityType,
        'entityId': entityId,
        'uid': user.uid,
        'role': effectiveRole,
        'route': route,
        'appVersion': appVersion,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
        'resolved': false,
      });
    } catch (loggerError) {
      if (kDebugMode) debugPrint('AppErrorLogger ignoré: $loggerError');
    } finally {
      _isWriting = false;
    }
  }

  Future<String> _readCurrentRole(String uid) async {
    try {
      final snapshot = await _firestore.collection('user_roles').doc(uid).get();
      final role = snapshot.data()?['role'];
      return role is String ? role : '';
    } catch (_) {
      return '';
    }
  }

  Future<void> setResolved(String logId, {required bool resolved}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _firestore.collection('app_error_logs').doc(logId).update({
      'resolved': resolved,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': user.uid,
    });
  }

  static StackFrameInfo parseRelevantStackFrame(StackTrace stackTrace) {
    for (final rawLine in stackTrace.toString().split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || _isFrameworkFrame(line)) continue;
      final match = RegExp(r'\((.+):(\d+):(\d+)\)').firstMatch(line);
      if (match != null) {
        final methodName = line
            .substring(0, match.start)
            .replaceFirst(RegExp(r'^#\d+\s+'), '')
            .trim();
        return StackFrameInfo(
          methodName: methodName.isEmpty ? null : methodName,
          sourceFile: _normalizeSourceFile(match.group(1)!),
          sourceLine: int.tryParse(match.group(2)!),
          sourceColumn: int.tryParse(match.group(3)!),
        );
      }
      final direct = RegExp(r'(.+?):(\d+):(\d+)').firstMatch(line);
      if (direct != null) {
        return StackFrameInfo(
          sourceFile: _normalizeSourceFile(direct.group(1)!),
          sourceLine: int.tryParse(direct.group(2)!),
          sourceColumn: int.tryParse(direct.group(3)!),
        );
      }
    }
    return const StackFrameInfo();
  }

  static String sanitizeErrorMessage(String message) {
    var value = _sanitize(message).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.length > 600) value = '${value.substring(0, 600)}…';
    return value;
  }

  static String sanitizeStackTrace(String stack) {
    var value = _sanitize(stack.split('\n').take(_maxStackLines).join('\n'));
    if (value.length > _maxStackLength) {
      value = '${value.substring(0, _maxStackLength)}\n…[trace tronquée]';
    }
    return value;
  }

  static String _sanitize(String value) {
    return value
        .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '<email masqué>')
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), '<token>')
        .replaceAll(
          RegExp(
            r'(password|mot\s*de\s*passe|secret|accessCode|apiKey|token|authorization|cookie)\s*[:=]\s*[^,\s}]+',
            caseSensitive: false,
          ),
          r'$1=<masqué>',
        )
        .replaceAll(RegExp(r'\+?\d[\d\s().-]{7,}\d'), '<téléphone masqué>');
  }

  static bool _isFrameworkFrame(String line) {
    return line.contains('(dart:') ||
        line.startsWith('dart:') ||
        line.contains('package:flutter/') ||
        line.contains('package:firebase_') ||
        line.contains('package:cloud_firestore/') ||
        line.contains('package:flutter_riverpod/');
  }

  static String _normalizeSourceFile(String value) {
    const packagePrefix = 'package:ayivonpome/';
    if (value.startsWith(packagePrefix)) {
      return 'lib/${value.substring(packagePrefix.length)}';
    }
    return value.replaceAll('\\', '/');
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
