import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_admin_auth_service.dart';

class FirebaseAccessCodeAuthService {
  const FirebaseAccessCodeAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String familyId,
    String editorEmail = 'editor@ayivon.app',
    String adminEmail = 'admin@ayivon.app',
    String superAdminEmail = 'ayivonaziangbede@gmail.com',
  }) : _auth = auth,
       _firestore = firestore,
       _familyId = familyId,
       _editorEmail = editorEmail,
       _adminEmail = adminEmail,
       _superAdminEmail = superAdminEmail;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _familyId;
  final String _editorEmail;
  final String _adminEmail;
  final String _superAdminEmail;

  Stream<User?> idTokenChanges() => _auth.idTokenChanges();

  User? get currentUser => _auth.currentUser;

  Future<FirebaseAdminSession?> restoreCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    final roleSnapshot = await _firestore
        .collection('user_roles')
        .doc(user.uid)
        .get();
    final roleData = roleSnapshot.data();
    if (roleData == null) return null;
    final active = roleData['active'] == true;
    final role = roleData['role'] as String? ?? '';
    final familyIds = (roleData['familyIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
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
    return _sessionFromRoleSnapshot(user, roleSnapshot);
  }

  Future<FirebaseAdminSession> signInWithAccessCode(String accessCode) async {
    final code = accessCode.trim();
    if (code.isEmpty) {
      throw const FirebaseAdminAuthException('Code incorrect.');
    }

    FirebaseAuthException? lastAuthError;
    for (final target in _technicalAccounts) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: target.email,
          password: code,
        );
        final user = credential.user;
        if (user == null) {
          throw const FirebaseAdminAuthException(
            'Session Firebase non créée après validation du code.',
          );
        }

        final roleSnapshot = await _firestore
            .collection('user_roles')
            .doc(user.uid)
            .get();
        final session = _sessionFromRoleSnapshot(
          user,
          roleSnapshot,
          expectedRoles: target.allowedRoles,
        );
        if (session == null) {
          await _auth.signOut();
          continue;
        }
        return session;
      } on FirebaseAuthException catch (error) {
        lastAuthError = error;
        continue;
      }
    }

    if (lastAuthError != null) {
      throw const FirebaseAdminAuthException('Code incorrect.');
    }
    throw const FirebaseAdminAuthException('Code incorrect.');
  }

  FirebaseAdminSession? _sessionFromRoleSnapshot(
    User user,
    DocumentSnapshot<Map<String, dynamic>> roleSnapshot, {
    Set<String>? expectedRoles,
    DateTime? expiresAt,
  }) {
    final roleData = roleSnapshot.data();
    if (roleData == null) return null;

    final role = roleData['role'] as String? ?? '';
    final authMethod =
        roleData['authMethod'] as String? ??
        (user.email == null || user.email!.isEmpty ? 'accessCode' : 'password');
    final active = roleData['active'] == true;
    final sessionExpiresAt = _readDateTime(roleData['sessionExpiresAt']);
    final familyIds = (roleData['familyIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    if (!active || !familyIds.contains(_familyId)) return null;
    if (sessionExpiresAt != null && !sessionExpiresAt.isAfter(DateTime.now())) {
      return null;
    }
    if (expectedRoles != null && !expectedRoles.contains(role)) return null;

    return FirebaseAdminSession(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      familyIds: familyIds,
      authMethod: authMethod.isEmpty ? 'password' : authMethod,
      expiresAt: expiresAt ?? sessionExpiresAt,
    );
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<_TechnicalAccountTarget> get _technicalAccounts => [
    _TechnicalAccountTarget(
      email: _editorEmail,
      allowedRoles: const {'editor'},
    ),
    _TechnicalAccountTarget(
      email: _adminEmail,
      allowedRoles: const {'admin', 'superAdmin'},
    ),
    if (_superAdminEmail.trim().isNotEmpty)
      _TechnicalAccountTarget(
        email: _superAdminEmail,
        allowedRoles: const {'superAdmin'},
      ),
  ];
}

class _TechnicalAccountTarget {
  const _TechnicalAccountTarget({
    required this.email,
    required this.allowedRoles,
  });

  final String email;
  final Set<String> allowedRoles;
}
