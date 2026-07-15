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

    final doc = _firestore.collection('user_roles').doc(normalizedUid);
    final snapshot = await doc.get();
    final existingData = snapshot.data();
    final createdAt = snapshot.exists
        ? existingData == null
              ? FieldValue.serverTimestamp()
              : existingData['createdAt'] ?? FieldValue.serverTimestamp()
        : FieldValue.serverTimestamp();
    await doc.set({
      'email': normalizedEmail,
      'role': normalizedRole,
      'familyIds': [_familyId],
      'active': active,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await _firestore.collection('user_roles').doc(normalizedUid).set({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!active) 'revokedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> revokeSession(String uid) {
    return setActive(uid, false);
  }

  Future<void> revokeAllOtherAccessCodeSessions() async {
    final current = currentUid;
    final snapshot = await _firestore
        .collection('user_roles')
        .where('familyIds', arrayContains: _familyId)
        .where('authMethod', isEqualTo: 'accessCode')
        .get();
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      if (doc.id == current) continue;
      batch.set(doc.reference, {
        'active': false,
        'revokedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasUpdates = true;
    }
    if (hasUpdates) {
      await batch.commit();
    }
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
    await _firestore.collection('user_roles').doc(normalizedUid).delete();
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
