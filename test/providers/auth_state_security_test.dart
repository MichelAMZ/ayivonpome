import 'dart:io';

import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cached or ambiguous role never grants sensitive access', () {
    const state = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'superAdmin'),
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
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
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
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'superAdmin'),
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
        mode: AuthMode.authenticated,
        session: const AuthSession(familyCode: 'ayivon', role: 'admin'),
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
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseRole: 'admin',
    );
    const missingRole = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'test-uid',
    );

    expect(missingUid.isAdmin, isFalse);
    expect(missingRole.hasFirebaseWriteAccess, isFalse);
  });

  test('access levels expose only their intended capabilities', () {
    const publicState = AuthState();
    const viewerState = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'viewer'),
      restoreStatus: SessionRestoreStatus.unauthenticated,
    );
    const editorState = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'editor'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'editor-uid',
      firebaseRole: 'editor',
    );
    const adminState = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
    );

    expect(publicState.accessLevel, AccessLevel.public);
    expect(publicState.canViewMemberDetails, isFalse);
    expect(publicState.canEdit, isFalse);
    expect(publicState.canShowEditButton, isFalse);
    expect(publicState.canDelete, isFalse);
    expect(publicState.canAccessKpi, isFalse);

    expect(viewerState.accessLevel, AccessLevel.viewer);
    expect(viewerState.canViewMemberDetails, isTrue);
    expect(viewerState.canEdit, isFalse);
    expect(viewerState.canShowEditButton, isTrue);
    expect(viewerState.canDelete, isFalse);
    expect(viewerState.canAccessKpi, isFalse);

    expect(editorState.accessLevel, AccessLevel.editor);
    expect(editorState.canViewMemberDetails, isTrue);
    expect(editorState.canEdit, isTrue);
    expect(editorState.canShowEditButton, isTrue);
    expect(editorState.canDelete, isTrue);
    expect(editorState.canAccessKpi, isFalse);

    expect(adminState.accessLevel, AccessLevel.admin);
    expect(adminState.canViewMemberDetails, isTrue);
    expect(adminState.canEdit, isTrue);
    expect(adminState.canShowEditButton, isTrue);
    expect(adminState.canDelete, isTrue);
    expect(adminState.canAccessKpi, isTrue);
  });

  test('access-code admin identity is limited to editor capabilities', () {
    const modificationSession = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseAuthMethod: 'accessCode',
    );
    const explicitAdminSession = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseAuthMethod: 'password',
    );

    expect(modificationSession.accessLevel, AccessLevel.editor);
    expect(modificationSession.canEdit, isTrue);
    expect(modificationSession.canAccessKpi, isFalse);
    expect(explicitAdminSession.accessLevel, AccessLevel.admin);
    expect(explicitAdminSession.canAccessKpi, isTrue);
  });

  test('viewer and cached identities never inherit editor or admin rights', () {
    const viewerWithStaleAdminMetadata = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'viewer'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'stale-uid',
      firebaseRole: 'admin',
    );
    const cachedEditor = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'editor'),
      restoreStatus: SessionRestoreStatus.error,
      firebaseUid: 'editor-uid',
      firebaseRole: 'editor',
    );

    expect(viewerWithStaleAdminMetadata.accessLevel, AccessLevel.viewer);
    expect(viewerWithStaleAdminMetadata.canEdit, isFalse);
    expect(viewerWithStaleAdminMetadata.canAccessKpi, isFalse);
    expect(cachedEditor.accessLevel, AccessLevel.public);
    expect(cachedEditor.canEdit, isFalse);
  });

  test('sensitive UI controls use explicit capabilities', () {
    final shell = File('lib/widgets/app_shell.dart').readAsStringSync();
    final details = File(
      'lib/screens/person_detail_screen.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/screens/dashboard_screen.dart',
    ).readAsStringSync();

    expect(shell, contains('if (auth.canAccessKpi)'));
    expect(
      details,
      contains('final canShowEditButton = auth.canShowEditButton;'),
    );
    expect(details, contains('onDelete: auth.canDelete'));
    expect(dashboard, contains('floatingActionButton: canEdit'));
  });

  test('all member profile entry points use the central viewer guard', () {
    for (final path in [
      'lib/screens/tree_screen.dart',
      'lib/screens/dashboard_screen.dart',
      'lib/screens/family_honor_hall_screen.dart',
      'lib/screens/linked_family_tree_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('ensureCanViewMemberDetails'),
        reason: '$path doit contrôler le droit viewer avant la navigation.',
      );
    }

    final card = File('lib/widgets/person_card.dart').readAsStringSync();
    final preview = File(
      'lib/widgets/person_preview_popup.dart',
    ).readAsStringSync();
    expect(
      card,
      contains('if (!ref.read(authSessionProvider).canViewMemberDetails)'),
    );
    expect(
      preview,
      contains('if (!ref.watch(authSessionProvider).canViewMemberDetails)'),
    );
  });

  test('direct profile route checks access before loading tree data', () {
    final source = File(
      'lib/screens/person_detail_screen.dart',
    ).readAsStringSync();
    final buildStart = source.indexOf(
      'Widget build(BuildContext context, WidgetRef ref)',
    );
    final accessCheck = source.indexOf(
      'if (!auth.canViewMemberDetails)',
      buildStart,
    );
    final dataWatch = source.indexOf(
      'ref.watch(familyTreeProvider)',
      buildStart,
    );

    expect(accessCheck, greaterThan(buildStart));
    expect(dataWatch, greaterThan(accessCheck));
    expect(source, contains('_MemberDetailAccessGate'));
  });

  test('modification authorization does not depend on auxiliary sync', () {
    final authSource = File(
      'lib/providers/auth_provider.dart',
    ).readAsStringSync();
    final dialogSource = File(
      'lib/widgets/modification_code_required_dialog.dart',
    ).readAsStringSync();

    expect(authSource, contains('return state.canEdit;'));
    expect(authSource, contains('_recordModificationAccessAudit'));
    expect(dialogSource, contains('if (widget.operationIds.isEmpty)'));
    expect(
      dialogSource,
      isNot(contains('.restoreSession()\n          .timeout')),
    );
  });

  test('admin access resumes the requested KPI navigation', () {
    final shell = File('lib/widgets/app_shell.dart').readAsStringSync();
    final authProvider = File(
      'lib/providers/auth_provider.dart',
    ).readAsStringSync();

    expect(shell, contains('.unlockAdmin(code)'));
    expect(shell, contains('const adminDashboardScreenIndex = 7;'));
    expect(shell, contains('_index = adminDashboardScreenIndex'));
    expect(shell, contains('_adminNavigationInProgress'));
    expect(shell, contains('if (_adminNavigationInProgress) return;'));
    expect(shell, contains('_adminNavigationInProgress = false;'));
    expect(authProvider, contains('Future<bool> unlockAdmin(String code)'));
    expect(authProvider, contains('return state.canAccessKpi;'));
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
