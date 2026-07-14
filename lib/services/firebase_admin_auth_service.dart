import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAdminSession {
  const FirebaseAdminSession({
    required this.uid,
    required this.email,
    required this.role,
    required this.familyIds,
  });

  final String uid;
  final String email;
  final String role;
  final List<String> familyIds;

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
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
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
      await _auth.signOut();
      throw const FirebaseAdminAuthException(
        'Aucun rôle applicatif Firestore n’est associé à ce compte.',
      );
    }

    final active = roleData['active'] == true;
    final role = _normalizeRole(roleData['role'] as String?);
    final familyIds = (roleData['familyIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    if (!active || role == null || !familyIds.contains(_familyId)) {
      await _auth.signOut();
      throw const FirebaseAdminAuthException(
        'Ce compte n’a pas les droits actifs pour cette famille.',
      );
    }

    return FirebaseAdminSession(
      uid: user.uid,
      email: user.email ?? email.trim(),
      role: role,
      familyIds: familyIds,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  static String? _normalizeRole(String? role) {
    return switch (role) {
      'superAdmin' => 'superAdmin',
      'admin' => 'admin',
      'editor' => 'editor',
      'viewer' => 'viewer',
      _ => null,
    };
  }
}

class FirebaseAdminAuthException implements Exception {
  const FirebaseAdminAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
