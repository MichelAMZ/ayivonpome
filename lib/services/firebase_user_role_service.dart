import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/firebase_user_role.dart';

class FirebaseUserRoleService {
  const FirebaseUserRoleService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required String familyId,
  }) : _firestore = firestore,
       _auth = auth,
       _familyId = familyId;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _familyId;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<FirebaseUserRole>> watchRoles() {
    return _firestore
        .collection('user_roles')
        .where('familyIds', arrayContains: _familyId)
        .snapshots()
        .map((snapshot) {
          final roles = snapshot.docs
              .map((doc) => FirebaseUserRole.fromFirestore(doc.id, doc.data()))
              .toList();
          roles.sort((a, b) => a.email.compareTo(b.email));
          return roles;
        });
  }

  Future<void> upsertRole({
    required String uid,
    required String email,
    required String role,
    required bool active,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedRole = _normalizeRole(role);
    if (normalizedUid.isEmpty) {
      throw const FirebaseUserRoleException('UID Firebase requis.');
    }
    if (normalizedEmail.isEmpty) {
      throw const FirebaseUserRoleException('Email requis.');
    }
    if (normalizedRole == null) {
      throw const FirebaseUserRoleException('Rôle Firebase invalide.');
    }
    if (normalizedUid == currentUid &&
        (normalizedRole != 'superAdmin' || !active)) {
      throw const FirebaseUserRoleException(
        'Le Super Admin connecté doit conserver un rôle superAdmin actif.',
      );
    }

    throw const FirebaseUserRoleException(
      'La gestion des rôles doit être effectuée par le service serveur.',
    );
  }

  Future<void> setActive(String uid, bool active) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const FirebaseUserRoleException('UID Firebase requis.');
    }
    if (normalizedUid == currentUid && !active) {
      throw const FirebaseUserRoleException(
        'Le Super Admin connecté ne peut pas désactiver son propre rôle.',
      );
    }
    throw const FirebaseUserRoleException(
      'La gestion des rôles doit être effectuée par le service serveur.',
    );
  }

  Future<void> revokeSession(String uid) {
    return setActive(uid, false);
  }

  Future<void> revokeAllOtherAccessCodeSessions() async {
    throw const FirebaseUserRoleException(
      'La révocation globale doit être effectuée par le service serveur.',
    );
  }

  Future<void> deleteRole(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const FirebaseUserRoleException('UID Firebase requis.');
    }
    if (normalizedUid == currentUid) {
      throw const FirebaseUserRoleException(
        'Le Super Admin connecté ne peut pas supprimer son propre rôle.',
      );
    }
    throw const FirebaseUserRoleException(
      'La suppression d’un rôle doit être effectuée par le service serveur.',
    );
  }

  String? _normalizeRole(String role) {
    return switch (role.trim()) {
      'superAdmin' => 'superAdmin',
      'admin' => 'admin',
      'editor' => 'editor',
      _ => null,
    };
  }
}

class FirebaseUserRoleException implements Exception {
  const FirebaseUserRoleException(this.message);

  final String message;

  @override
  String toString() => message;
}
