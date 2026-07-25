import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/firebase_user_role.dart';

class FirebaseAdminSession {
  const FirebaseAdminSession({
    required this.uid,
    required this.email,
    required this.role,
    required this.familyIds,
    this.authMethod = 'password',
    this.expiresAt,
  });

  final String uid;
  final String email;
  final String role;
  final List<String> familyIds;
  final String authMethod;
  final DateTime? expiresAt;

  bool get isSuperAdmin => role == 'superAdmin';
  bool get isAdmin => role == 'admin' || isSuperAdmin;
  bool get isEditor => role == 'editor' || isAdmin;
}

class FirebaseAdminAuthService {
  const FirebaseAdminAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String familyId,
  }) : _auth = auth,
       _firestore = firestore,
       _familyId = familyId;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _familyId;

  Future<FirebaseAdminSession> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != 'ayivonaziangbede@gmail.com') {
      throw const FirebaseAdminAuthException(
        'Identifiants administrateur invalides.',
      );
    }
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const FirebaseAdminAuthException('Compte Firebase introuvable.');
    }

    final roleSnapshot = await _firestore
        .collection('user_roles')
        .doc(user.uid)
        .get();
    final roleData = roleSnapshot.data();
    if (roleData == null) {
      _debugRoleResolution(user.uid, roleFound: false);
      await _auth.signOut();
      throw const FirebaseAdminAuthException(
        'Aucun rôle applicatif Firestore n’est associé à ce compte.',
      );
    }

    final active = FirebaseUserRole.readActive(roleData);
    final role = FirebaseUserRole.normalizedRole(roleData['role']);
    final familyIds = FirebaseUserRole.readFamilyIds(roleData);
    _debugRoleResolution(user.uid, roleFound: true, role: role, active: active);

    if (!active || role == null || !familyIds.contains(_familyId)) {
      await _auth.signOut();
      throw const FirebaseAdminAuthException(
        'Ce compte n’a pas les droits actifs pour cette famille.',
      );
    }

    return FirebaseAdminSession(
      uid: user.uid,
      email: user.email ?? normalizedEmail,
      role: role,
      familyIds: familyIds,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateCurrentAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email != 'ayivonaziangbede@gmail.com') {
      throw const FirebaseAdminAuthException(
        'Le compte administrateur AYIVON doit être connecté.',
      );
    }
    final verifiedEmail = email!;
    final credential = EmailAuthProvider.credential(
      email: verifiedEmail,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() => _auth.signOut();

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

class FirebaseAdminAuthException implements Exception {
  const FirebaseAdminAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
