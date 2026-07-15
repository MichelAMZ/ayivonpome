import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/diagnostic_report.dart';
import '../models/family_tree_data.dart';
import '../models/sync_incident.dart';
import 'connectivity_service.dart';
import 'json_storage_service.dart';

class DiagnosticService {
  const DiagnosticService({
    required ConnectivityService connectivity,
    required JsonStorageService localStorage,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _connectivity = connectivity,
       _localStorage = localStorage,
       _firestore = firestore,
       _auth = auth;

  final ConnectivityService _connectivity;
  final JsonStorageService _localStorage;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  Future<DiagnosticReport> run({
    required FamilyTreeData data,
    required List<SyncIncident> incidents,
  }) async {
    final checks = <DiagnosticCheck>[];
    checks.add(await _checkInternet());
    checks.add(await _checkFirebase());
    checks.add(await _checkAuthentication());
    checks.add(await _checkFirestoreFamilyRead(data.mainFamilyCode));
    checks.add(await _checkFirestoreMemberRead(data.mainFamilyCode));
    checks.add(await _checkFirestoreMemberWrite(data.mainFamilyCode));
    checks.add(await _checkLocalDatabase());
    checks.add(_checkSynchronization(data));

    return _buildReport(data: data, incidents: incidents, checks: checks);
  }

  Future<DiagnosticReport> testFirestore({
    required FamilyTreeData data,
    required List<SyncIncident> incidents,
  }) async {
    final checks = [
      await _checkFirestoreFamilyRead(data.mainFamilyCode),
      await _checkFirestoreMemberRead(data.mainFamilyCode),
      await _checkFirestoreMemberWrite(data.mainFamilyCode),
    ];
    return _buildReport(data: data, incidents: incidents, checks: checks);
  }

  String buildTextReport(DiagnosticReport report) {
    final buffer = StringBuffer()
      ..writeln('========================================')
      ..writeln('AYIVON')
      ..writeln('Centre de diagnostic')
      ..writeln('========================================')
      ..writeln()
      ..writeln('Date : ${report.generatedAt.toIso8601String()}')
      ..writeln('Version : ${report.version}')
      ..writeln('Plateforme : ${report.platform}')
      ..writeln('Utilisateur : ${report.userLabel}')
      ..writeln('UID : ${report.uid}')
      ..writeln()
      ..writeln('----------------------------------------')
      ..writeln('ETAT GENERAL')
      ..writeln('----------------------------------------')
      ..writeln('Internet : ${report.networkStatus}')
      ..writeln('Firebase : ${report.firebaseStatus}')
      ..writeln('Firestore : ${report.firestoreStatus}')
      ..writeln('Authentication : ${report.authStatus}')
      ..writeln('Base locale : ${report.localDatabaseStatus}')
      ..writeln('Synchronisation : ${report.syncStatus}')
      ..writeln();

    for (final check in report.checks) {
      buffer.writeln(
        '${check.label} : ${check.statusLabel}'
        '${check.responseTimeMs == null ? '' : ' (${check.responseTimeMs} ms)'}'
        ' - ${check.message}',
      );
      if (check.collectionName.isNotEmpty ||
          check.documentPath.isNotEmpty ||
          check.ruleName.isNotEmpty) {
        buffer
          ..writeln('  Collection : ${check.collectionName}')
          ..writeln('  Document : ${check.documentPath}')
          ..writeln('  Règle : ${check.ruleName}');
      }
    }

    buffer
      ..writeln()
      ..writeln('----------------------------------------')
      ..writeln('DETAIL DES ERREURS')
      ..writeln('----------------------------------------');

    final failedChecks = report.checks.where((check) => !check.ok).toList();
    if (report.errors.isEmpty && failedChecks.isEmpty) {
      buffer.writeln('Aucune erreur enregistrée.');
    }
    for (var index = 0; index < failedChecks.length; index++) {
      final check = failedChecks[index];
      buffer
        ..writeln()
        ..writeln('Erreur ${index + 1}')
        ..writeln('Test : ${check.label}')
        ..writeln('Collection : ${check.collectionName}')
        ..writeln('Document : ${check.documentPath}')
        ..writeln('Règle concernée : ${check.ruleName}')
        ..writeln(
          'Code : ${check.code.isEmpty ? 'diagnostic-error' : check.code}',
        )
        ..writeln('Message : ${check.message}')
        ..writeln('Durée : ${check.responseTimeMs ?? 0} ms')
        ..writeln(
          'Type : ${check.errorType.isEmpty ? 'DiagnosticError' : check.errorType}',
        )
        ..writeln(
          'Fichier : ${check.sourceFile.isEmpty ? 'Localisation indisponible' : check.sourceFile}',
        )
        ..writeln(
          'Méthode : ${check.sourceFunction.isEmpty ? 'Localisation indisponible' : check.sourceFunction}',
        )
        ..writeln(
          'Ligne : ${check.sourceLine?.toString() ?? 'Localisation indisponible'}',
        )
        ..writeln(
          'Colonne : ${check.sourceColumn?.toString() ?? 'Localisation indisponible'}',
        )
        ..writeln('StackTrace :')
        ..writeln(
          check.stackTrace.trim().isEmpty
              ? 'Localisation indisponible.'
              : check.stackTrace,
        )
        ..writeln('----------------------------------------');
    }
    for (var index = 0; index < report.errors.length; index++) {
      final incident = report.errors[index];
      buffer
        ..writeln()
        ..writeln('Incident ${index + 1}')
        ..writeln('Date : ${incident.lastOccurredAt}')
        ..writeln('Type : ${incident.errorType}')
        ..writeln('Firebase Code : ${incident.errorCode}')
        ..writeln('Message : ${incident.safeMessage}')
        ..writeln('Technique : ${incident.technicalMessage}')
        ..writeln('Collection : ${incident.collectionName}')
        ..writeln('Document : ${incident.documentId}')
        ..writeln('Classe : ${_classFromSource(incident.sourceFile)}')
        ..writeln(
          'Méthode : ${incident.sourceFunction.isEmpty ? 'Localisation indisponible' : incident.sourceFunction}',
        )
        ..writeln(
          'Fichier : ${incident.sourceFile.isEmpty ? 'Localisation indisponible' : incident.sourceFile}',
        )
        ..writeln(
          'Ligne : ${incident.sourceLine?.toString() ?? 'Localisation indisponible'}',
        )
        ..writeln(
          'Colonne : ${incident.sourceColumn?.toString() ?? 'Localisation indisponible'}',
        )
        ..writeln('Plateforme : ${incident.platform}')
        ..writeln('Version application : ${incident.appVersion}')
        ..writeln('Nombre de tentatives : ${incident.attemptCount}')
        ..writeln('StackTrace :')
        ..writeln(
          incident.stackTrace.trim().isEmpty
              ? 'Localisation indisponible.'
              : incident.stackTrace,
        )
        ..writeln('----------------------------------------');
    }

    buffer
      ..writeln()
      ..writeln('========================================')
      ..writeln('FIN DU RAPPORT')
      ..writeln('========================================');
    return buffer.toString();
  }

  Future<DiagnosticCheck> _checkInternet() async {
    return _timedCheck('Connexion Internet', () async {
      final online = await _connectivity.isOnline.timeout(
        const Duration(seconds: 5),
      );
      if (!online) {
        throw StateError('Connexion Internet indisponible.');
      }
      return 'Connexion disponible.';
    });
  }

  Future<DiagnosticCheck> _checkFirebase() async {
    return _timedCheck('Firebase', () async {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      }
      return Firebase.apps.isEmpty
          ? 'Firebase non initialisé.'
          : 'Firebase initialisé.';
    });
  }

  Future<DiagnosticCheck> _checkAuthentication() async {
    return _timedCheck('Firebase Authentication', () async {
      final user = _auth?.currentUser;
      if (user == null) {
        throw const _DiagnosticFailure(
          code: 'unauthenticated',
          message: 'Aucun utilisateur Firebase connecté.',
        );
      }
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? const <String, dynamic>{};
      final firestore = _firestore;
      if (firestore == null) {
        throw const _DiagnosticFailure(
          code: 'firestore-not-initialized',
          message: 'Firestore non initialisé.',
        );
      }
      final roleSnapshot = await firestore
          .collection('user_roles')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final roleData = roleSnapshot.data();
      final familyIds = (roleData?['familyIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      final role = roleData?['role'] as String?;
      final active = roleData?['active'] == true;
      final validRole = role == 'superAdmin' || role == 'admin';
      if (roleData == null ||
          !active ||
          !validRole ||
          !familyIds.contains('ayivon')) {
        throw const _DiagnosticFailure(
          code: 'admin-role-denied',
          message:
              'Le compte Firebase connecté n’a pas de rôle admin actif pour ayivon.',
        );
      }
      return 'UID=${user.uid} email=${user.email ?? '-'} anonymous=${user.isAnonymous} '
          'method=${claims['authMethod'] ?? roleData['authMethod'] ?? '-'} '
          'role=${claims['role'] ?? role} familyId=${claims['familyId'] ?? 'ayivon'}';
    });
  }

  Future<DiagnosticCheck> _checkFirestoreFamilyRead(String familyId) async {
    final normalizedFamilyId = familyId.isEmpty ? 'ayivon' : familyId;
    return _timedCheck(
      'Firestore Lecture families',
      () async {
        final firestore = _firestore;
        if (firestore == null) {
          throw const _DiagnosticFailure(
            code: 'firestore-not-initialized',
            message: 'Firestore non initialisé.',
          );
        }
        final doc = await firestore
            .collection('families')
            .doc(normalizedFamilyId)
            .get()
            .timeout(const Duration(seconds: 8));
        return doc.exists
            ? 'families/${doc.id} lu.'
            : 'warning:not-found|Firestore accessible, families/$normalizedFamilyId absent.';
      },
      collectionName: 'families',
      documentPath: 'families/$normalizedFamilyId',
      ruleName: 'match /families/{familyId} allow read',
    );
  }

  Future<DiagnosticCheck> _checkFirestoreMemberRead(String familyId) async {
    final normalizedFamilyId = familyId.isEmpty ? 'ayivon' : familyId;
    return _timedCheck(
      'Firestore Lecture members',
      () async {
        final firestore = _firestore;
        if (firestore == null) {
          throw const _DiagnosticFailure(
            code: 'firestore-not-initialized',
            message: 'Firestore non initialisé.',
          );
        }
        final snapshot = await firestore
            .collection('members')
            .where('familyId', isEqualTo: normalizedFamilyId)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));
        if (snapshot.docs.isEmpty) {
          return 'warning:not-found|Firestore accessible, aucun membre $normalizedFamilyId trouvé.';
        }
        return 'members/${snapshot.docs.first.id} lu.';
      },
      collectionName: 'members',
      documentPath: 'members?familyId=$normalizedFamilyId',
      ruleName: 'match /members/{memberId} allow read',
    );
  }

  Future<DiagnosticCheck> _checkFirestoreMemberWrite(String familyId) async {
    final normalizedFamilyId = familyId.isEmpty ? 'ayivon' : familyId;
    return _timedCheck(
      'Firestore Ecriture members',
      () async {
        final firestore = _firestore;
        if (firestore == null) {
          throw const _DiagnosticFailure(
            code: 'firestore-not-initialized',
            message: 'Firestore non initialisé.',
          );
        }
        final user = _auth?.currentUser;
        if (user == null) {
          throw const _DiagnosticFailure(
            code: 'unauthenticated',
            message: 'Aucun utilisateur Firebase connecté.',
          );
        }
        final now = DateTime.now().toUtc().toIso8601String();
        final docId =
            '_diagnostic_${user.uid}_${DateTime.now().microsecondsSinceEpoch}';
        final doc = firestore.collection('members').doc(docId);
        await doc
            .set({
              'id': docId,
              'familyId': normalizedFamilyId,
              'firstName': 'Diagnostic',
              'lastName': 'Firestore',
              'gender': 'unknown',
              'deletedAt': now,
              'createdAt': now,
              'updatedAt': now,
              'version': 1,
              'diagnostic': true,
              'createdBy': user.uid,
            })
            .timeout(const Duration(seconds: 8));
        await doc.get().timeout(const Duration(seconds: 8));
        await doc.delete().timeout(const Duration(seconds: 8));
        return 'Création, lecture et suppression OK sur members/$docId.';
      },
      collectionName: 'members',
      documentPath: 'members/_diagnostic_<uid>_<timestamp>',
      ruleName:
          'match /members/{memberId} allow create + allow read + allow delete',
    );
  }

  Future<DiagnosticCheck> _checkLocalDatabase() async {
    return _timedCheck('Base locale', () async {
      final exists = await _localStorage.exists().timeout(
        const Duration(seconds: 5),
      );
      final location = await _localStorage.storageLocation().timeout(
        const Duration(seconds: 5),
      );
      return 'OK exists=$exists location=$location';
    });
  }

  DiagnosticCheck _checkSynchronization(FamilyTreeData data) {
    final failed = data.pendingSyncQueue
        .where((item) => item.status == 'failed')
        .length;
    return DiagnosticCheck(
      label: 'Synchronisation',
      ok: _auth?.currentUser != null && failed == 0,
      code: _auth?.currentUser == null ? 'unauthenticated' : '',
      message: _auth?.currentUser == null
          ? 'Inactive - session Firebase absente'
          : 'En attente=${data.pendingSyncQueue.length}, echecs=$failed, derniere=${data.syncSettings.lastSyncAt.isEmpty ? '-' : data.syncSettings.lastSyncAt}',
    );
  }

  Future<DiagnosticCheck> _timedCheck(
    String label,
    Future<String> Function() action, {
    String collectionName = '',
    String documentPath = '',
    String ruleName = '',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final message = await action();
      stopwatch.stop();
      if (message.startsWith('warning:')) {
        final parts = message.substring(8).split('|');
        return DiagnosticCheck(
          label: label,
          ok: true,
          warning: true,
          code: parts.first,
          message: parts.length > 1 ? parts.sublist(1).join('|') : parts.first,
          collectionName: collectionName,
          documentPath: documentPath,
          ruleName: ruleName,
          responseTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
      return DiagnosticCheck(
        label: label,
        ok: true,
        message: message,
        collectionName: collectionName,
        documentPath: documentPath,
        ruleName: ruleName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on FirebaseException catch (error, stackTrace) {
      stopwatch.stop();
      return DiagnosticCheck(
        label: label,
        ok: false,
        code: error.code,
        errorType: 'FirebaseException',
        message:
            '${error.code}${error.message == null ? '' : ' - ${error.message}'}',
        stackTrace: stackTrace.toString(),
        collectionName: collectionName,
        documentPath: documentPath,
        ruleName: ruleName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on _DiagnosticFailure catch (error, stackTrace) {
      stopwatch.stop();
      return DiagnosticCheck(
        label: label,
        ok: false,
        code: error.code,
        errorType: '_DiagnosticFailure',
        message: error.message,
        stackTrace: stackTrace.toString(),
        collectionName: collectionName,
        documentPath: documentPath,
        ruleName: ruleName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      return DiagnosticCheck(
        label: label,
        ok: false,
        code: 'diagnostic-error',
        errorType: error.runtimeType.toString(),
        message: error.toString(),
        stackTrace: stackTrace.toString(),
        collectionName: collectionName,
        documentPath: documentPath,
        ruleName: ruleName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  List<SyncIncident> _latestErrors(List<SyncIncident> incidents) {
    final sorted = [...incidents]
      ..sort((a, b) => b.lastOccurredAt.compareTo(a.lastOccurredAt));
    return sorted.take(200).toList();
  }

  DiagnosticReport _buildReport({
    required FamilyTreeData data,
    required List<SyncIncident> incidents,
    required List<DiagnosticCheck> checks,
  }) {
    final user = _auth?.currentUser;
    return DiagnosticReport(
      generatedAt: DateTime.now(),
      checks: checks,
      errors: _latestErrors(incidents),
      pendingSyncCount: data.pendingSyncQueue.length,
      failedSyncCount: data.pendingSyncQueue
          .where((item) => item.status == 'failed')
          .length,
      lastSyncAt: data.syncSettings.lastSyncAt,
      userLabel: user?.email ?? (user?.isAnonymous == true ? 'anonymous' : '-'),
      uid: user?.uid ?? '-',
      platform: _platformLabel(),
      version: '1.0.0+1',
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  String _classFromSource(String sourceFile) {
    final name = sourceFile.split('/').last.replaceAll('.dart', '');
    if (name.trim().isEmpty) return 'Localisation indisponible';
    return name
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
  }
}

class _DiagnosticFailure implements Exception {
  const _DiagnosticFailure({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}
