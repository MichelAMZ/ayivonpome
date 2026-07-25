import 'dart:async';
import 'dart:io';

import 'package:ayivonpome/services/firebase_access_code_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAccessCodeAuthService', () {
    for (final role in const ['viewer', 'editor', 'admin', 'superAdmin']) {
      test('accepte un code valide avec un rôle $role actif', () async {
        final client = _FakeAccessCodeAuthClient(
          identity: AccessCodeIdentity(
            uid: 'uid-$role',
            email: '',
            role: role,
            familyId: 'ayivon',
          ),
          roleData: <String, dynamic>{
            'role': role,
            'familyIds': const ['ayivon'],
            'active': true,
            'authMethod': 'accessCode',
          },
        );
        final service = FirebaseAccessCodeAuthService(
          client: client,
          familyId: 'ayivon',
          deviceId: 'device-test',
        );

        final session = await service.signInWithAccessCode('  code-$role  ');

        expect(session.role, role);
        expect(session.authMethod, 'accessCode');
        expect(client.receivedCode, 'code-$role');
        expect(client.receivedFamilyId, 'ayivon');
        expect(client.receivedDeviceId, 'device-test');
      });
    }

    test('rejette un code vide sans appeler la Function', () async {
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

    test(
      'remplace ou réutilise une session existante via le custom token',
      () async {
        final client = _validClient();
        final service = FirebaseAccessCodeAuthService(
          client: client,
          familyId: 'ayivon',
        );

        await service.signInWithAccessCode('valid-code');
        await service.signInWithAccessCode('valid-code');

        expect(client.authenticateCalls, 2);
        expect(client.signOutCalls, 0);
      },
    );

    test('rejette un rôle absent ou inactif et ferme la session', () async {
      for (final roleData in <Map<String, dynamic>?>[
        null,
        <String, dynamic>{
          'role': 'editor',
          'familyIds': const ['ayivon'],
          'active': false,
        },
      ]) {
        final client = _FakeAccessCodeAuthClient(
          identity: const AccessCodeIdentity(
            uid: 'technical-user',
            email: '',
            role: 'editor',
            familyId: 'ayivon',
          ),
          roleData: roleData,
        );
        final service = FirebaseAccessCodeAuthService(
          client: client,
          familyId: 'ayivon',
        );

        await expectLater(
          service.signInWithAccessCode('valid-code'),
          throwsA(isA<FirebaseAccessCodeAuthException>()),
        );
        expect(client.signOutCalls, 1);
      }
    });

    test(
      'ne transforme pas une Function indisponible en code incorrect',
      () async {
        final client = _FakeAccessCodeAuthClient(
          authenticationError: const FirebaseAccessCodeAuthException(
            'Service temporairement indisponible.',
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

    test('le client ne lit jamais les collections de codes protégées', () {
      final source = File(
        'lib/services/firebase_access_code_auth_service.dart',
      ).readAsStringSync();

      expect(source, isNot(contains(".collection('access_code_configs')")));
      expect(source, isNot(contains(".collection('access_codes')")));
      expect(source, isNot(contains('signInWithEmailAndPassword')));
      expect(source, isNot(contains('debugPrint(accessCode')));
    });
  });
}

_FakeAccessCodeAuthClient _validClient({Map<String, dynamic>? roleData}) {
  return _FakeAccessCodeAuthClient(
    identity: const AccessCodeIdentity(
      uid: 'technical-user',
      email: '',
      role: 'editor',
      familyId: 'ayivon',
    ),
    roleData:
        roleData ??
        <String, dynamic>{
          'role': 'editor',
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
