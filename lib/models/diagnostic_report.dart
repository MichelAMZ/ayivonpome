import 'sync_incident.dart';

class DiagnosticCheck {
  const DiagnosticCheck({
    required this.label,
    required this.ok,
    required this.message,
    this.warning = false,
    this.code = '',
    this.errorType = '',
    this.stackTrace = '',
    this.sourceFile = '',
    this.sourceFunction = '',
    this.collectionName = '',
    this.documentPath = '',
    this.ruleName = '',
    this.sourceLine,
    this.sourceColumn,
    this.responseTimeMs,
  });

  final String label;
  final bool ok;
  final bool warning;
  final String message;
  final String code;
  final String errorType;
  final String stackTrace;
  final String sourceFile;
  final String sourceFunction;
  final String collectionName;
  final String documentPath;
  final String ruleName;
  final int? sourceLine;
  final int? sourceColumn;
  final int? responseTimeMs;

  String get statusLabel => ok ? (warning ? 'AVERTISSEMENT' : 'OK') : 'ECHEC';
}

class DiagnosticReport {
  const DiagnosticReport({
    required this.generatedAt,
    required this.checks,
    required this.errors,
    required this.pendingSyncCount,
    required this.failedSyncCount,
    required this.lastSyncAt,
    required this.userLabel,
    required this.uid,
    required this.platform,
    required this.version,
  });

  final DateTime generatedAt;
  final List<DiagnosticCheck> checks;
  final List<SyncIncident> errors;
  final int pendingSyncCount;
  final int failedSyncCount;
  final String lastSyncAt;
  final String userLabel;
  final String uid;
  final String platform;
  final String version;

  DiagnosticCheck? get lastFailedCheck {
    for (final check in checks.reversed) {
      if (!check.ok) return check;
    }
    return null;
  }

  bool get hasResults => checks.isNotEmpty;

  bool get hasErrors => checks.any((check) => !check.ok) || errors.isNotEmpty;

  String get firestoreStatus {
    final firestoreChecks = checks.where(
      (check) => check.label.toLowerCase().contains('firestore'),
    );
    if (firestoreChecks.any((check) => !check.ok)) return 'ECHEC';
    if (firestoreChecks.any((check) => check.warning)) {
      return 'AVERTISSEMENT';
    }
    return firestoreChecks.isEmpty ? '-' : 'OK';
  }

  String get firebaseStatus {
    final check = _firstCheck('Firebase');
    return check?.statusLabel ?? '-';
  }

  String get authStatus {
    final check = _firstCheck('Firebase Authentication');
    return check?.statusLabel ?? '-';
  }

  String get networkStatus {
    final check = _firstCheck('Connexion Internet');
    return check?.statusLabel ?? '-';
  }

  String get localDatabaseStatus {
    final check = _firstCheck('Base locale');
    return check?.statusLabel ?? '-';
  }

  String get syncStatus {
    if (uid == '-') return 'Inactive - session Firebase absente';
    return failedSyncCount == 0 ? 'OK' : '$failedSyncCount erreur(s)';
  }

  DiagnosticCheck? _firstCheck(String label) {
    for (final check in checks) {
      if (check.label == label) return check;
    }
    return null;
  }
}
