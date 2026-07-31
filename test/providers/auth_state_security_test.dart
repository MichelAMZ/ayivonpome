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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
    );

    expect(state.isAdmin, isTrue);
    expect(state.isSuperAdmin, isTrue);
  });

  test(
    'effective family authorization uses active role and family membership',
    () {
      AuthState authorized(String role) => AuthState(
        mode: AuthMode.authenticated,
        session: AuthSession(familyCode: 'ayivon', role: role),
        restoreStatus: SessionRestoreStatus.authenticated,
        firebaseUid: '$role-uid',
        firebaseRole: role,
        firebaseRoleActive: true,
        firebaseFamilyIds: const {'ayivon'},
      );

      for (final role in ['editor', 'admin', 'superAdmin']) {
        expect(authorized(role).canWriteFamily('AYIVON'), isTrue);
      }
      expect(authorized('viewer').canWriteFamily('ayivon'), isFalse);
      expect(authorized('admin').canWriteFamily('another-family'), isFalse);
      expect(
        const AuthState(
          mode: AuthMode.authenticated,
          session: AuthSession(familyCode: 'ayivon', role: 'admin'),
          restoreStatus: SessionRestoreStatus.authenticated,
          firebaseUid: 'inactive-admin',
          firebaseRole: 'admin',
          firebaseFamilyIds: {'ayivon'},
        ).canWriteFamily('ayivon'),
        isFalse,
      );
      expect(authorized('editor').canAccessAdminKpi('ayivon'), isFalse);
      expect(authorized('admin').canAccessAdminKpi('ayivon'), isTrue);
    },
  );

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
        firebaseRoleActive: true,
        firebaseFamilyIds: const {'ayivon'},
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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
    );
    const adminState = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
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
    expect(editorState.canDelete, isFalse);
    expect(editorState.canAccessKpi, isFalse);

    expect(adminState.accessLevel, AccessLevel.admin);
    expect(adminState.canViewMemberDetails, isTrue);
    expect(adminState.canEdit, isTrue);
    expect(adminState.canShowEditButton, isTrue);
    expect(adminState.canDelete, isTrue);
    expect(adminState.canAccessKpi, isTrue);
  });

  test(
    'modification code keeps writes but never grants KPI administration',
    () {
      const modificationSession = AuthState(
        mode: AuthMode.authenticated,
        session: AuthSession(familyCode: 'ayivon', role: 'admin'),
        restoreStatus: SessionRestoreStatus.authenticated,
        firebaseUid: 'admin-uid',
        firebaseRole: 'admin',
        firebaseRoleActive: true,
        firebaseFamilyIds: {'ayivon'},
        firebaseAuthMethod: 'accessCode',
      );
      const explicitAdminSession = AuthState(
        mode: AuthMode.authenticated,
        session: AuthSession(familyCode: 'ayivon', role: 'admin'),
        restoreStatus: SessionRestoreStatus.authenticated,
        firebaseUid: 'admin-uid',
        firebaseRole: 'admin',
        firebaseRoleActive: true,
        firebaseFamilyIds: {'ayivon'},
        firebaseAuthMethod: 'password',
      );

      expect(modificationSession.accessLevel, AccessLevel.editor);
      expect(modificationSession.canEdit, isTrue);
      expect(modificationSession.canDelete, isFalse);
      expect(modificationSession.canAccessKpi, isFalse);
      expect(explicitAdminSession.accessLevel, AccessLevel.admin);
      expect(explicitAdminSession.canDelete, isTrue);
      expect(explicitAdminSession.canAccessKpi, isTrue);
    },
  );

  test('verified Firebase role overrides stale local viewer metadata', () {
    const viewerWithStaleAdminMetadata = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'viewer'),
      restoreStatus: SessionRestoreStatus.authenticated,
      firebaseUid: 'stale-uid',
      firebaseRole: 'admin',
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
    );
    const cachedEditor = AuthState(
      mode: AuthMode.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'editor'),
      restoreStatus: SessionRestoreStatus.error,
      firebaseUid: 'editor-uid',
      firebaseRole: 'editor',
    );

    expect(viewerWithStaleAdminMetadata.accessLevel, AccessLevel.admin);
    expect(viewerWithStaleAdminMetadata.canEdit, isTrue);
    expect(viewerWithStaleAdminMetadata.canAccessKpi, isTrue);
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
    expect(
      shell,
      contains(
        'if (authenticated && !auth.canAccessKpi) const SizedBox.shrink()',
      ),
    );
    expect(
      shell,
      contains('if (auth.canAccessKpi) const LinkedFamiliesScreen()'),
    );
    expect(shell, contains('final notificationsIndex = canAccessKpi ? 5 : 4;'));
    expect(shell, contains('(auth.canAccessKpi ? 5 : 4)'));
    expect(authProvider, contains('Future<bool> unlockAdmin(String code)'));
    expect(authProvider, contains('return state.canAccessKpi;'));
    expect(authProvider, contains('_explicitAuthenticationInProgress = true;'));
    expect(
      authProvider,
      contains('_explicitAuthenticationInProgress = false;'),
    );
    expect(
      authProvider,
      contains("latestStoredSession.authMethod == 'password'"),
    );
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
