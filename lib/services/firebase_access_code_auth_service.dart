import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/firebase_user_role.dart';
import 'firebase_admin_auth_service.dart';

enum AccessCodeAuthFailure { invalidCode, unavailable, failed }

class FirebaseAccessCodeAuthException extends FirebaseAdminAuthException {
  const FirebaseAccessCodeAuthException(super.message, this.failure);

  final AccessCodeAuthFailure failure;
}

class AccessCodeIdentity {
  const AccessCodeIdentity({
    required this.uid,
    required this.email,
    required this.role,
    required this.familyId,
    this.expiresAt,
  });

  final String uid;
  final String email;
  final String role;
  final String familyId;
  final DateTime? expiresAt;
}

abstract class AccessCodeAuthClient {
  Stream<User?> idTokenChanges();

  User? get currentUser;

  Future<AccessCodeIdentity> authenticate({
    required String familyId,
    required String accessCode,
    required String deviceId,
    required String appVersion,
  });

  Future<Map<String, dynamic>?> loadRole(String uid);

  Future<void> signOut();
}

class FirebaseAccessCodeAuthClient implements AccessCodeAuthClient {
  FirebaseAccessCodeAuthClient({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) : _auth = auth,
       _firestore = firestore,
       _functions = functions;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<User?> idTokenChanges() => _auth.idTokenChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AccessCodeIdentity> authenticate({
    required String familyId,
    required String accessCode,
    required String deviceId,
    required String appVersion,
  }) async {
    try {
      final callable = _functions.httpsCallable('authenticateWithAccessCode');
      final result = await callable.call(<String, dynamic>{
        'familyId': familyId,
        'accessCode': accessCode,
        'deviceId': deviceId,
        'appVersion': appVersion,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final customToken = data['customToken'] as String? ?? '';
      final returnedFamilyId = data['familyId'] as String? ?? '';
      final role = FirebaseUserRole.normalizedRole(data['role']) ?? '';
      final expiresAt = DateTime.tryParse(data['expiresAt'] as String? ?? '');
      if (customToken.isEmpty ||
          returnedFamilyId != familyId ||
          !{'viewer', 'editor', 'admin', 'superAdmin'}.contains(role)) {
        throw const FirebaseAccessCodeAuthException(
          'Réponse d’authentification invalide.',
          AccessCodeAuthFailure.failed,
        );
      }

      final credential = await _auth.signInWithCustomToken(customToken);
      final user = credential.user;
      if (user == null) {
        throw const FirebaseAccessCodeAuthException(
          'Session Firebase non créée après validation du code.',
          AccessCodeAuthFailure.failed,
        );
      }
      await user.getIdToken(true);
      return AccessCodeIdentity(
        uid: user.uid,
        email: user.email ?? '',
        role: role,
        familyId: returnedFamilyId,
        expiresAt: expiresAt,
      );
    } on FirebaseAccessCodeAuthException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'unauthenticated' ||
          error.code == 'invalid-argument') {
        throw const FirebaseAccessCodeAuthException(
          'Code incorrect.',
          AccessCodeAuthFailure.invalidCode,
        );
      }
      if (error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'internal') {
        throw const FirebaseAccessCodeAuthException(
          'Service d’authentification temporairement indisponible.',
          AccessCodeAuthFailure.unavailable,
        );
      }
      throw const FirebaseAccessCodeAuthException(
        'Échec du service d’authentification.',
        AccessCodeAuthFailure.failed,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw const FirebaseAccessCodeAuthException(
          'Réseau indisponible pendant l’authentification.',
          AccessCodeAuthFailure.unavailable,
        );
      }
      throw const FirebaseAccessCodeAuthException(
        'Impossible de créer la session Firebase.',
        AccessCodeAuthFailure.failed,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> loadRole(String uid) async {
    final snapshot = await _firestore.collection('user_roles').doc(uid).get();
    return snapshot.data();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseAccessCodeAuthService {
  const FirebaseAccessCodeAuthService({
    required AccessCodeAuthClient client,
    required String familyId,
    this.deviceId = '',
    this.appVersion = '1.0.0+1',
  }) : _client = client,
       _familyId = familyId;

  final AccessCodeAuthClient _client;
  final String _familyId;
  final String deviceId;
  final String appVersion;

  Stream<User?> idTokenChanges() => _client.idTokenChanges();

  User? get currentUser => _client.currentUser;

  Future<FirebaseAdminSession?> restoreCurrentSession() async {
    final user = _client.currentUser;
    if (user == null || user.isAnonymous) return null;
    final roleData = await _client.loadRole(user.uid);
    if (roleData == null) return null;
    final active = FirebaseUserRole.readActive(roleData);
    final role = FirebaseUserRole.normalizedRole(roleData['role']) ?? '';
    final familyIds = FirebaseUserRole.readFamilyIds(roleData);
    _debugRoleResolution(user.uid, roleFound: true, role: role, active: active);
    final sessionExpiresAt = _readDateTime(roleData['sessionExpiresAt']);
    if (!active) {
      throw const FirebaseAdminAuthException('Session révoquée.');
    }
    if (!{'viewer', 'editor', 'admin', 'superAdmin'}.contains(role) ||
        !familyIds.contains(_familyId)) {
      throw const FirebaseAdminAuthException('Session non autorisée.');
    }
    if (sessionExpiresAt != null && !sessionExpiresAt.isAfter(DateTime.now())) {
      throw const FirebaseAdminAuthException('Session expirée.');
    }
    return _sessionFromRoleData(
      uid: user.uid,
      email: user.email ?? '',
      roleData: roleData,
    );
  }

  Future<FirebaseAdminSession> signInWithAccessCode(String accessCode) async {
    final code = accessCode.trim();
    if (code.isEmpty) {
      throw const FirebaseAccessCodeAuthException(
        'Code incorrect.',
        AccessCodeAuthFailure.invalidCode,
      );
    }

    final identity = await _client.authenticate(
      familyId: _familyId,
      accessCode: code,
      deviceId: deviceId,
      appVersion: appVersion,
    );
    final roleData = await _client.loadRole(identity.uid);
    final session = roleData == null
        ? null
        : _sessionFromRoleData(
            uid: identity.uid,
            email: identity.email,
            roleData: roleData,
            expectedRole: identity.role,
            expiresAt: identity.expiresAt,
          );
    if (session == null) {
      await _client.signOut();
      throw const FirebaseAccessCodeAuthException(
        'Ce compte n’a pas les droits actifs pour cette famille.',
        AccessCodeAuthFailure.failed,
      );
    }
    return session;
  }

  FirebaseAdminSession? _sessionFromRoleData({
    required String uid,
    required String email,
    required Map<String, dynamic> roleData,
    String? expectedRole,
    DateTime? expiresAt,
  }) {
    final role = FirebaseUserRole.normalizedRole(roleData['role']) ?? '';
    final authMethod = roleData['authMethod'] as String? ?? 'accessCode';
    final active = FirebaseUserRole.readActive(roleData);
    final sessionExpiresAt = _readDateTime(roleData['sessionExpiresAt']);
    final familyIds = FirebaseUserRole.readFamilyIds(roleData);
    _debugRoleResolution(uid, roleFound: true, role: role, active: active);
    if (!active || !familyIds.contains(_familyId)) return null;
    if (sessionExpiresAt != null && !sessionExpiresAt.isAfter(DateTime.now())) {
      return null;
    }
    if (expectedRole != null && expectedRole != role) return null;

    return FirebaseAdminSession(
      uid: uid,
      email: email,
      role: role,
      familyIds: familyIds,
      authMethod: authMethod.isEmpty ? 'accessCode' : authMethod,
      expiresAt: expiresAt ?? sessionExpiresAt,
    );
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _debugRoleResolution(
    String uid, {
    required bool roleFound,
    String? role,
    bool? active,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'AUTH ROLE uid=$uid familyId=$_familyId '
      'found=$roleFound role=${role ?? 'absent'} active=${active ?? false}',
    );
  }
}
