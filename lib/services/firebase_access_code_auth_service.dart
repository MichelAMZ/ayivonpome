import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/firebase_user_role.dart';
import 'firebase_admin_auth_service.dart';

enum AccessCodeAuthFailure {
  invalidCode,
  unavailable,
  accountDisabled,
  roleMissing,
  roleInactive,
  roleInvalid,
  failed,
}

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
    String adminEmail = 'ayivonaziangbede@gmail.com',
  }) : _auth = auth,
       _firestore = firestore,
       _adminEmail = adminEmail;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _adminEmail;

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
      final credential = await _auth.signInWithEmailAndPassword(
        email: _adminEmail,
        password: accessCode,
      );
      final user = credential.user;
      if (user == null) {
        throw const FirebaseAccessCodeAuthException(
          'Session Firebase absente.',
          AccessCodeAuthFailure.failed,
        );
      }
      await user.getIdToken(true);
      return AccessCodeIdentity(
        uid: user.uid,
        email: user.email ?? _adminEmail,
        role: 'admin',
        familyId: familyId,
      );
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthError(error.code);
    }
  }

  @visibleForTesting
  static FirebaseAccessCodeAuthException mapFirebaseAuthError(String code) {
    if (code == 'wrong-password' ||
        code == 'invalid-credential' ||
        code == 'user-not-found' ||
        code == 'invalid-email') {
      return const FirebaseAccessCodeAuthException(
        'Code secret incorrect.',
        AccessCodeAuthFailure.invalidCode,
      );
    }
    if (code == 'network-request-failed' ||
        code == 'too-many-requests' ||
        code == 'operation-not-allowed') {
      return const FirebaseAccessCodeAuthException(
        'Connexion Internet ou service d’authentification indisponible.',
        AccessCodeAuthFailure.unavailable,
      );
    }
    if (code == 'user-disabled') {
      return const FirebaseAccessCodeAuthException(
        'Compte désactivé.',
        AccessCodeAuthFailure.accountDisabled,
      );
    }
    return const FirebaseAccessCodeAuthException(
      'Impossible de créer la session Firebase.',
      AccessCodeAuthFailure.failed,
    );
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

  Future<void> signOut() => _client.signOut();

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
    return _signInWithCode(accessCode, authMethod: 'accessCode');
  }

  Future<FirebaseAdminSession> signInWithAdminCode(String accessCode) async {
    return _signInWithCode(accessCode, authMethod: 'password');
  }

  Future<FirebaseAdminSession> _signInWithCode(
    String accessCode, {
    required String authMethod,
  }) async {
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
    if (roleData == null) {
      await _client.signOut();
      throw const FirebaseAccessCodeAuthException(
        'Configuration du rôle manquante.',
        AccessCodeAuthFailure.roleMissing,
      );
    }
    if (!FirebaseUserRole.readActive(roleData)) {
      await _client.signOut();
      throw const FirebaseAccessCodeAuthException(
        'Compte désactivé.',
        AccessCodeAuthFailure.roleInactive,
      );
    }
    final session = _sessionFromRoleData(
      uid: identity.uid,
      email: identity.email,
      roleData: roleData,
      expectedRole: identity.role,
      expiresAt: identity.expiresAt,
      authMethodOverride: authMethod,
    );
    if (session == null) {
      await _client.signOut();
      throw const FirebaseAccessCodeAuthException(
        'Rôle non autorisé pour cette famille.',
        AccessCodeAuthFailure.roleInvalid,
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
    String? authMethodOverride,
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
      authMethod:
          authMethodOverride ??
          (authMethod.isEmpty ? 'accessCode' : authMethod),
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
