import 'dart:async';
import 'dart:io';

import 'package:ayivonpome/services/firebase_access_code_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAccessCodeAuthService', () {
    test('accepte le mot de passe du compte admin unique', () async {
      final client = _FakeAccessCodeAuthClient(
        identity: const AccessCodeIdentity(
          uid: 'uid-admin',
          email: 'ayivonaziangbede@gmail.com',
          role: 'admin',
          familyId: 'ayivon',
        ),
        roleData: <String, dynamic>{
          'role': 'admin',
          'familyIds': const ['ayivon'],
          'active': true,
          'authMethod': 'password',
        },
      );
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
        deviceId: 'device-test',
      );

      final session = await service.signInWithAccessCode('  mot-de-passe  ');

      expect(session.role, 'admin');
      expect(session.authMethod, 'password');
      expect(client.receivedCode, 'mot-de-passe');
      expect(client.receivedFamilyId, 'ayivon');
      expect(client.receivedDeviceId, 'device-test');
    });

    test('refuse un rôle non-admin pour le compte unique', () async {
      final client = _FakeAccessCodeAuthClient(
        identity: const AccessCodeIdentity(
          uid: 'uid-admin',
          email: 'ayivonaziangbede@gmail.com',
          role: 'admin',
          familyId: 'ayivon',
        ),
        roleData: <String, dynamic>{
          'role': 'viewer',
          'familyIds': const ['ayivon'],
          'active': true,
        },
      );
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      await expectLater(
        service.signInWithAccessCode('mot-de-passe'),
        throwsA(
          isA<FirebaseAccessCodeAuthException>().having(
            (error) => error.failure,
            'failure',
            AccessCodeAuthFailure.roleInvalid,
          ),
        ),
      );
    });

    test('rejette un code vide sans appeler Firebase Auth', () async {
      final client = _FakeAccessCodeAuthClient();
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      await expectLater(
        service.signInWithAccessCode('   '),
        throwsA(
          isA<FirebaseAccessCodeAuthException>().having(
            (error) => error.failure,
            'failure',
            AccessCodeAuthFailure.invalidCode,
          ),
        ),
      );
      expect(client.authenticateCalls, 0);
    });

    test('fonctionne sans session Firebase préalable', () async {
      final client = _validClient();
      expect(client.currentUser, isNull);
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      final session = await service.signInWithAccessCode('valid-code');

      expect(session.uid, 'technical-user');
    });

    test('remplace ou réutilise une session Firebase existante', () async {
      final client = _validClient();
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      await service.signInWithAccessCode('valid-code');
      await service.signInWithAccessCode('valid-code');

      expect(client.authenticateCalls, 2);
      expect(client.signOutCalls, 0);
    });

    test('distingue un rôle absent et ferme la session', () async {
      final client = _FakeAccessCodeAuthClient(
        identity: const AccessCodeIdentity(
          uid: 'technical-user',
          email: '',
          role: 'admin',
          familyId: 'ayivon',
        ),
      );
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      await expectLater(
        service.signInWithAccessCode('valid-code'),
        throwsA(
          isA<FirebaseAccessCodeAuthException>().having(
            (error) => error.failure,
            'failure',
            AccessCodeAuthFailure.roleMissing,
          ),
        ),
      );
      expect(client.signOutCalls, 1);
    });

    test('distingue un rôle inactif et ferme la session', () async {
      final client = _FakeAccessCodeAuthClient(
        identity: const AccessCodeIdentity(
          uid: 'technical-user',
          email: '',
          role: 'admin',
          familyId: 'ayivon',
        ),
        roleData: <String, dynamic>{
          'role': 'admin',
          'familyIds': const ['ayivon'],
          'active': false,
        },
      );
      final service = FirebaseAccessCodeAuthService(
        client: client,
        familyId: 'ayivon',
      );

      await expectLater(
        service.signInWithAccessCode('valid-code'),
        throwsA(
          isA<FirebaseAccessCodeAuthException>().having(
            (error) => error.failure,
            'failure',
            AccessCodeAuthFailure.roleInactive,
          ),
        ),
      );
      expect(client.signOutCalls, 1);
    });

    test('distingue code incorrect, réseau et compte désactivé', () {
      expect(
        FirebaseAccessCodeAuthClient.mapFirebaseAuthError(
          'invalid-credential',
        ).failure,
        AccessCodeAuthFailure.invalidCode,
      );
      expect(
        FirebaseAccessCodeAuthClient.mapFirebaseAuthError(
          'network-request-failed',
        ).failure,
        AccessCodeAuthFailure.unavailable,
      );
      expect(
        FirebaseAccessCodeAuthClient.mapFirebaseAuthError(
          'user-disabled',
        ).failure,
        AccessCodeAuthFailure.accountDisabled,
      );
    });

    test(
      'propage une erreur réseau sans la présenter comme code incorrect',
      () async {
        final client = _FakeAccessCodeAuthClient(
          authenticationError: const FirebaseAccessCodeAuthException(
            'Connexion Internet indisponible.',
            AccessCodeAuthFailure.unavailable,
          ),
        );
        final service = FirebaseAccessCodeAuthService(
          client: client,
          familyId: 'ayivon',
        );

        await expectLater(
          service.signInWithAccessCode('valid-code'),
          throwsA(
            isA<FirebaseAccessCodeAuthException>().having(
              (error) => error.failure,
              'failure',
              AccessCodeAuthFailure.unavailable,
            ),
          ),
        );
      },
    );

    test('le client utilise Firebase Auth sans Function ni stockage local', () {
      final source = File(
        'lib/services/firebase_access_code_auth_service.dart',
      ).readAsStringSync();

      expect(source, contains('signInWithEmailAndPassword'));
      expect(source, contains('ayivonaziangbede@gmail.com'));
      expect(source, isNot(contains('viewer@ayivon.app')));
      expect(source, isNot(contains('admin@ayivon.app')));
      expect(source, isNot(contains('superadmin@ayivon.app')));
      expect(source, isNot(contains('httpsCallable')));
      expect(source, isNot(contains(".collection('access_code_configs')")));
      expect(source, isNot(contains(".collection('access_codes')")));
      expect(source, isNot(contains('SharedPreferences')));
      expect(source, isNot(contains('debugPrint(accessCode')));
      expect(source, isNot(contains('debugPrint(password')));
    });

    test('le code viewer initial reste un accès local en lecture', () {
      final source = File(
        'lib/providers/auth_provider.dart',
      ).readAsStringSync();

      expect(source, contains("normalizedCode == 'ayivon'"));
      expect(source, contains("accessCode.role == 'viewer'"));
      expect(source, contains("role: 'viewer'"));
    });
  });
}

_FakeAccessCodeAuthClient _validClient({Map<String, dynamic>? roleData}) {
  return _FakeAccessCodeAuthClient(
    identity: const AccessCodeIdentity(
      uid: 'technical-user',
      email: '',
      role: 'admin',
      familyId: 'ayivon',
    ),
    roleData:
        roleData ??
        <String, dynamic>{
          'role': 'admin',
          'familyIds': const ['ayivon'],
          'active': true,
          'authMethod': 'accessCode',
        },
  );
}

class _FakeAccessCodeAuthClient implements AccessCodeAuthClient {
  _FakeAccessCodeAuthClient({
    this.identity,
    this.roleData,
    this.authenticationError,
  });

  final AccessCodeIdentity? identity;
  final Map<String, dynamic>? roleData;
  final Object? authenticationError;
  int authenticateCalls = 0;
  int signOutCalls = 0;
  String? receivedCode;
  String? receivedFamilyId;
  String? receivedDeviceId;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> idTokenChanges() => const Stream<User?>.empty();

  @override
  Future<AccessCodeIdentity> authenticate({
    required String familyId,
    required String accessCode,
    required String deviceId,
    required String appVersion,
  }) async {
    authenticateCalls++;
    receivedFamilyId = familyId;
    receivedCode = accessCode;
    receivedDeviceId = deviceId;
    if (authenticationError != null) throw authenticationError!;
    return identity!;
  }

  @override
  Future<Map<String, dynamic>?> loadRole(String uid) async => roleData;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
