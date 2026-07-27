import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_metadata.dart';
import '../services/auth_code_service.dart';
import '../services/firebase_admin_auth_service.dart';
import 'app_providers.dart';
import 'family_tree_provider.dart';

enum AuthMode { publicLimited, authenticated }

enum AccessLevel { public, viewer, editor, admin }

enum SessionRestoreStatus {
  initializing,
  authenticated,
  unauthenticated,
  unauthorized,
  error,
}

class AuthState {
  const AuthState({
    this.mode = AuthMode.publicLimited,
    this.restoreStatus = SessionRestoreStatus.initializing,
    this.session,
    this.hasModificationAccess = false,
    this.firebaseUid,
    this.firebaseEmail,
    this.firebaseRole,
    this.firebaseAuthMethod,
    this.lastSessionError,
  });

  final AuthMode mode;
  final SessionRestoreStatus restoreStatus;
  final AuthSession? session;
  final bool hasModificationAccess;
  final String? firebaseUid;
  final String? firebaseEmail;
  final String? firebaseRole;
  final String? firebaseAuthMethod;
  final String? lastSessionError;

  bool get isAuthenticated => mode == AuthMode.authenticated && session != null;
  bool get isInitializing => restoreStatus == SessionRestoreStatus.initializing;
  bool get hasFirebaseWriteAccess =>
      restoreStatus == SessionRestoreStatus.authenticated &&
      firebaseUid != null &&
      firebaseUid!.isNotEmpty &&
      (firebaseRole == 'editor' ||
          firebaseRole == 'admin' ||
          firebaseRole == 'superAdmin');
  AccessLevel get accessLevel {
    if (!isAuthenticated) return AccessLevel.public;
    if (session?.role == 'viewer') {
      return AccessLevel.viewer;
    }
    if (!hasFirebaseWriteAccess) return AccessLevel.public;
    if (firebaseAuthMethod == 'accessCode') return AccessLevel.editor;
    if (firebaseRole == 'admin' || firebaseRole == 'superAdmin') {
      return AccessLevel.admin;
    }
    return AccessLevel.editor;
  }

  bool get canViewMemberDetails => accessLevel != AccessLevel.public;
  bool get canEdit =>
      accessLevel == AccessLevel.editor || accessLevel == AccessLevel.admin;
  bool get canShowEditButton => canViewMemberDetails;
  bool get canDelete => canEdit;
  bool get canAccessKpi => accessLevel == AccessLevel.admin;
  bool get canModify => canEdit;
  bool get isSuperAdmin => canAccessKpi && firebaseRole == 'superAdmin';
  bool get isAdmin => canAccessKpi;
  bool get canSecurelyDeleteMember => canDelete;
}

final authSessionProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final service = ref.read(firebaseAccessCodeAuthServiceProvider);
    if (service == null) {
      return const AuthState(
        restoreStatus: SessionRestoreStatus.unauthenticated,
      );
    }
    final subscription = service.idTokenChanges().listen((user) {
      if (user == null || user.isAnonymous) {
        final current = state;
        if (current.isAuthenticated &&
            current.firebaseUid == null &&
            current.session?.role == 'viewer') {
          return;
        }
        unawaited(
          ref.read(familyTreeProvider.notifier).startRemoteFamilyTreeWatch(),
        );
        state = const AuthState(
          restoreStatus: SessionRestoreStatus.unauthenticated,
        );
        return;
      }
      Future.microtask(restoreSession);
    });
    ref.onDispose(subscription.cancel);
    Future.microtask(restoreSession);
    return const AuthState();
  }

  Future<bool> restoreSession() async {
    final service = ref.read(firebaseAccessCodeAuthServiceProvider);
    if (service == null) {
      await ref.read(familyTreeProvider.notifier).stopRemoteFamilyTreeWatch();
      state = const AuthState(
        restoreStatus: SessionRestoreStatus.unauthenticated,
      );
      return false;
    }
    final currentUser = service.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      await ref.read(familyTreeProvider.notifier).startRemoteFamilyTreeWatch();
      state = const AuthState(
        restoreStatus: SessionRestoreStatus.unauthenticated,
      );
      return false;
    }
    final storedSession = await ref
        .read(sessionStorageServiceProvider)
        .readSession();
    try {
      final firebaseSession = await service.restoreCurrentSession();
      if (firebaseSession == null) {
        if (storedSession != null && storedSession.uid == currentUser.uid) {
          _applyStoredSession(storedSession);
        } else {
          state = AuthState(
            restoreStatus: SessionRestoreStatus.unauthorized,
            firebaseUid: currentUser.uid,
            firebaseEmail: currentUser.email,
            lastSessionError: 'Rôle applicatif indisponible.',
          );
        }
        return false;
      }
      _applyFirebaseSession(firebaseSession);
      await _saveSessionMetadata(firebaseSession);
      await ref
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch(
            includeActivityLog: firebaseSession.isAdmin,
          );
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
      return true;
    } catch (error) {
      if (_isConfirmedAuthorizationFailure(error)) {
        await ref
            .read(familyTreeProvider.notifier)
            .startRemoteFamilyTreeWatch();
        await ref.read(sessionStorageServiceProvider).clearSession();
        state = AuthState(
          restoreStatus: SessionRestoreStatus.unauthorized,
          firebaseUid: currentUser.uid,
          firebaseEmail: currentUser.email,
          lastSessionError: '$error',
        );
        return false;
      }
      if (storedSession != null && storedSession.uid == currentUser.uid) {
        _applyStoredSession(
          storedSession,
          lastSessionError: 'Firestore temporairement indisponible : $error',
        );
      } else {
        state = AuthState(
          restoreStatus: SessionRestoreStatus.error,
          firebaseUid: currentUser.uid,
          firebaseEmail: currentUser.email,
          lastSessionError: '$error',
        );
      }
      return false;
    }
  }

  Future<bool> login(String code) async {
    final normalizedCode = code.trim().toLowerCase();
    final configuredViewerCodes =
        (ref.read(familyTreeProvider).value?.accessCodes ?? const [])
            .where(
              (accessCode) =>
                  accessCode.enabled &&
                  !accessCode.isExpired &&
                  accessCode.role == 'viewer',
            )
            .toList(growable: false);
    final validViewerCode = configuredViewerCodes.isEmpty
        ? normalizedCode == 'ayivon'
        : configuredViewerCodes.any(
            (accessCode) =>
                accessCode.code.trim().toLowerCase() == normalizedCode,
          );
    if (validViewerCode) {
      state = const AuthState(
        mode: AuthMode.authenticated,
        restoreStatus: SessionRestoreStatus.authenticated,
        session: AuthSession(familyCode: 'ayivon', role: 'viewer'),
      );
      await ref.read(familyTreeProvider.notifier).startRemoteFamilyTreeWatch();
      return true;
    }
    final firebaseSession = await _tryFirebaseAccessCodeLogin(code);
    if (firebaseSession != null) {
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
      return true;
    }

    return false;
  }

  Future<void> loginFirebaseAdmin({
    required String email,
    required String password,
  }) async {
    final service = ref.read(firebaseAdminAuthServiceProvider);
    if (service == null) {
      throw const FirebaseAdminAuthException(
        'Firebase n’est pas initialisé pour cet environnement.',
      );
    }
    final firebaseSession = await service.signIn(
      email: email,
      password: password,
    );
    _applyFirebaseSession(firebaseSession);
    await _saveSessionMetadata(firebaseSession);
    await ref
        .read(familyTreeProvider.notifier)
        .startRemoteFamilyTreeWatch(
          includeActivityLog: firebaseSession.isAdmin,
        );
    await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
  }

  Future<void> sendFirebasePasswordReset(String email) async {
    final service = ref.read(firebaseAdminAuthServiceProvider);
    if (service == null) {
      throw const FirebaseAdminAuthException(
        'Firebase n’est pas initialisé pour cet environnement.',
      );
    }
    await service.sendPasswordReset(email);
  }

  Future<bool> unlockModification(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) return false;

    final firebaseAccessCodeService = ref.read(
      firebaseAccessCodeAuthServiceProvider,
    );
    if (firebaseAccessCodeService == null) {
      await _recordModificationAccessAudit(
        'modification_code_refused',
        description: 'Authentification Firebase requise.',
        actorRole: state.session?.role ?? 'viewer',
      );
      return false;
    }

    late final FirebaseAdminSession firebaseSession;
    try {
      firebaseSession = await firebaseAccessCodeService.signInWithAccessCode(
        trimmedCode,
      );
      if (!firebaseSession.isEditor) {
        await firebaseAccessCodeService.signOut();
        await _recordModificationAccessAudit(
          'modification_code_refused',
          description: 'Rôle sans droit de modification.',
          actorRole: state.session?.role ?? 'viewer',
        );
        return false;
      }
    } catch (_) {
      await _recordModificationAccessAudit(
        'modification_code_refused',
        description: 'Code de modification incorrect ou compte non autorisé.',
        actorRole: state.session?.role ?? 'viewer',
      );
      return false;
    }

    _applyFirebaseSession(firebaseSession);

    try {
      await _saveSessionMetadata(firebaseSession);
    } catch (_) {
      // La session Firebase courante reste la source d'autorité.
    }
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch(
            includeActivityLog: firebaseSession.isAdmin,
          );
    } catch (_) {
      // Le listener pourra être relancé sans invalider l'authentification.
    }
    await _recordModificationAccessAudit(
      'modification_code_accepted',
      description: 'Accès modification autorisé via Firebase Auth.',
      actorRole: firebaseSession.role,
    );
    try {
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
    } catch (_) {
      // Le nettoyage est secondaire et ne doit pas invalider un code correct.
    }

    return state.canEdit;
  }

  Future<bool> unlockAdmin(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) return false;

    final service = ref.read(firebaseAccessCodeAuthServiceProvider);
    if (service == null) return false;

    late final FirebaseAdminSession firebaseSession;
    try {
      firebaseSession = await service.signInWithAdminCode(trimmedCode);
      if (!firebaseSession.isAdmin) {
        await service.signOut();
        return false;
      }
    } catch (_) {
      return false;
    }

    _applyFirebaseSession(firebaseSession);
    try {
      await _saveSessionMetadata(firebaseSession);
    } catch (_) {
      // La session Firebase validée reste la source d'autorité.
    }
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch(includeActivityLog: true);
    } catch (_) {
      // Le listener pourra être relancé sans annuler l'accès administrateur.
    }
    try {
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
    } catch (_) {
      // Le nettoyage est secondaire à l'authentification.
    }
    return state.canAccessKpi;
  }

  Future<void> _recordModificationAccessAudit(
    String action, {
    required String description,
    required String actorRole,
  }) async {
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .addAuditLog(action, description: description, actorRole: actorRole);
    } catch (_) {
      // La journalisation ne doit jamais modifier le résultat d'authentification.
    }
  }

  Future<void> logout() async {
    final service = ref.read(firebaseAdminAuthServiceProvider);
    if (service != null && state.firebaseUid != null) {
      await service.signOut();
    }
    await ref.read(sessionStorageServiceProvider).clearSession();
    state = const AuthState(
      restoreStatus: SessionRestoreStatus.unauthenticated,
    );
    await ref.read(familyTreeProvider.notifier).startRemoteFamilyTreeWatch();
  }

  Future<FirebaseAdminSession?> _tryFirebaseAccessCodeLogin(
    String code, {
    bool requireEditor = false,
  }) async {
    final service = ref.read(firebaseAccessCodeAuthServiceProvider);
    if (service == null) return null;
    try {
      final firebaseSession = await service.signInWithAccessCode(code);
      if (requireEditor && !firebaseSession.isEditor) return null;
      _applyFirebaseSession(firebaseSession);
      await _saveSessionMetadata(firebaseSession);
      await ref
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch(
            includeActivityLog: firebaseSession.isAdmin,
          );
      return firebaseSession;
    } catch (_) {
      return null;
    }
  }

  void _applyFirebaseSession(FirebaseAdminSession firebaseSession) {
    final session = AuthSession(
      familyCode: firebaseSession.familyIds.first,
      role: firebaseSession.role,
    );
    state = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: session,
      hasModificationAccess: firebaseSession.isEditor,
      firebaseUid: firebaseSession.uid,
      firebaseEmail: firebaseSession.email,
      firebaseRole: firebaseSession.role,
      firebaseAuthMethod: firebaseSession.authMethod,
    );
  }

  void _applyStoredSession(
    SessionMetadata sessionMetadata, {
    String? lastSessionError,
  }) {
    final session = AuthSession(
      familyCode: sessionMetadata.familyId,
      role: sessionMetadata.role,
    );
    state = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: lastSessionError == null
          ? SessionRestoreStatus.authenticated
          : SessionRestoreStatus.error,
      session: session,
      hasModificationAccess: _isEditorRole(sessionMetadata.role),
      firebaseUid: sessionMetadata.uid,
      firebaseRole: sessionMetadata.role,
      firebaseAuthMethod: sessionMetadata.authMethod,
      lastSessionError: lastSessionError,
    );
  }

  Future<void> _saveSessionMetadata(
    FirebaseAdminSession firebaseSession,
  ) async {
    await ref
        .read(sessionStorageServiceProvider)
        .saveSession(
          SessionMetadata(
            uid: firebaseSession.uid,
            familyId: firebaseSession.familyIds.first,
            role: firebaseSession.role,
            signedInAt: DateTime.now(),
            expiresAt: firebaseSession.expiresAt ?? _defaultSessionExpiry(),
            appVersion: '1.0.0+1',
            authMethod: firebaseSession.authMethod,
          ),
        );
  }

  DateTime _defaultSessionExpiry() {
    return DateTime.now().add(const Duration(days: 30));
  }

  bool _isEditorRole(String role) {
    return role == 'editor' || role == 'admin' || role == 'superAdmin';
  }

  bool _isConfirmedAuthorizationFailure(Object error) {
    if (error is! FirebaseAdminAuthException) return false;
    final message = error.message;
    return message.contains('révoquée') ||
        message.contains('non autorisée') ||
        message.contains('expirée');
  }
}
