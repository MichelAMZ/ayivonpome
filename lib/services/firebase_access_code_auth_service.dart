import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'firebase_admin_auth_service.dart';

class FirebaseAccessCodeAuthService {
  const FirebaseAccessCodeAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required String familyId,
  }) : _auth = auth,
       _firestore = firestore,
       _functions = functions,
       _familyId = familyId;

  static const _deviceIdKey = 'firebase_access_code_device_id';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String _familyId;

  Future<FirebaseAdminSession?> restoreCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    final roleSnapshot = await _firestore
        .collection('user_roles')
        .doc(user.uid)
        .get();
    final session = _sessionFromRoleSnapshot(user, roleSnapshot);
    if (session == null) {
      await _auth.signOut();
    }
    return session;
  }

  Future<FirebaseAdminSession> signInWithAccessCode(String accessCode) async {
    final deviceId = await _deviceId();
    final callable = _functions.httpsCallable('authenticateWithAccessCode');
    final result = await callable.call<Map<String, dynamic>>({
      'familyId': _familyId,
      'accessCode': accessCode.trim(),
      'deviceId': deviceId,
      'appVersion': '1.0.0+1',
    });
    final data = Map<String, dynamic>.from(result.data);
    final customToken = data['customToken'] as String? ?? '';
    final expectedRole = data['role'] as String? ?? '';
    if (customToken.isEmpty) {
      throw const FirebaseAdminAuthException(
        'Authentification par code indisponible.',
      );
    }

    final credential = await _auth.signInWithCustomToken(customToken);
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
      expectedRole: expectedRole,
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
    );
    if (session == null) {
      await _auth.signOut();
      throw const FirebaseAdminAuthException(
        'La session Firebase ne correspond pas au rôle demandé.',
      );
    }

    return session;
  }

  FirebaseAdminSession? _sessionFromRoleSnapshot(
    User user,
    DocumentSnapshot<Map<String, dynamic>> roleSnapshot, {
    String? expectedRole,
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
    if (expectedRole != null && role != expectedRole) return null;

    return FirebaseAdminSession(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      familyIds: familyIds,
      authMethod: authMethod,
      expiresAt: expiresAt ?? sessionExpiresAt,
    );
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final next = const Uuid().v4();
    await prefs.setString(_deviceIdKey, next);
    return next;
  }
}
