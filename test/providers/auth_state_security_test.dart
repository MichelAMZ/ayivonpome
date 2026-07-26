import 'dart:io';

import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cached or ambiguous role never grants sensitive access', () {
    const state = AuthState(
      restoreStatus: SessionRestoreStatus.error,
      firebaseUid: 'test-uid',
      firebaseRole: 'superAdmin',
    );

    expect(state.hasFirebaseWriteAccess, isFalse);
    expect(state.canModify, isFalse);
    expect(state.isAdmin, isFalse);
    expect(state.isSuperAdmin, isFalse);
  });

  test('verified Firebase admin role grants admin access', () {
    const state = AuthState(
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'test-uid',
      firebaseRole: 'admin',
    );

    expect(state.hasFirebaseWriteAccess, isTrue);
    expect(state.canModify, isTrue);
    expect(state.isAdmin, isTrue);
    expect(state.isSuperAdmin, isFalse);
  });

  test('verified Firebase super admin role grants super admin access', () {
    const state = AuthState(
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'test-uid',
      firebaseRole: 'superAdmin',
    );

    expect(state.isAdmin, isTrue);
    expect(state.isSuperAdmin, isTrue);
  });

  test('expired or signed-out session denies KPI and writes', () {
    for (final status in [
      SessionRestoreStatus.unauthenticated,
      SessionRestoreStatus.unauthorized,
      SessionRestoreStatus.error,
    ]) {
      final state = AuthState(
        restoreStatus: status,
        firebaseUid: 'stale-uid',
        firebaseRole: 'admin',
      );

      expect(state.hasFirebaseWriteAccess, isFalse);
      expect(state.isAdmin, isFalse);
      expect(state.canSecurelyDeleteMember, isFalse);
    }
  });

  test('missing Firebase UID or role never grants cached access', () {
    const missingUid = AuthState(
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseRole: 'admin',
    );
    const missingRole = AuthState(
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'test-uid',
    );

    expect(missingUid.isAdmin, isFalse);
    expect(missingRole.hasFirebaseWriteAccess, isFalse);
  });

  test('viewer login starts the realtime tree listener', () {
    final source = File('lib/providers/auth_provider.dart').readAsStringSync();
    final viewerBranch = source.substring(
      source.indexOf('if (validViewerCode)'),
      source.indexOf(
        'final firebaseSession',
        source.indexOf('if (validViewerCode)'),
      ),
    );

    expect(viewerBranch, contains('startRemoteFamilyTreeWatch'));
    expect(viewerBranch, contains("role: 'viewer'"));
  });

  test('public Firestore listener is not stopped by Firebase sign-out', () {
    final source = File('lib/providers/auth_provider.dart').readAsStringSync();
    final signedOutBranch = source.substring(
      source.indexOf('if (user == null || user.isAnonymous)'),
      source.indexOf('Future.microtask(restoreSession)'),
    );
    final logoutBranch = source.substring(
      source.indexOf('Future<void> logout()'),
      source.indexOf(
        'Future<FirebaseAdminSession?> _tryFirebaseAccessCodeLogin',
      ),
    );

    expect(signedOutBranch, contains('startRemoteFamilyTreeWatch'));
    expect(signedOutBranch, isNot(contains('stopRemoteFamilyTreeWatch')));
    expect(logoutBranch, contains('startRemoteFamilyTreeWatch'));
    expect(logoutBranch, isNot(contains('stopRemoteFamilyTreeWatch')));
  });

  test('a signed-out Firebase user cannot retain a cached admin role', () {
    const signedOut = AuthState(
      mode: AuthMode.publicLimited,
      restoreStatus: SessionRestoreStatus.unauthenticated,
      firebaseRole: 'admin',
    );

    expect(signedOut.isAdmin, isFalse);
    expect(signedOut.canModify, isFalse);
  });
}
