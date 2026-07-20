import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_metadata.dart';
import '../services/auth_code_service.dart';
import '../services/firebase_admin_auth_service.dart';
import 'app_providers.dart';
import 'family_tree_provider.dart';

enum AuthMode { publicLimited, authenticated }

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
      firebaseRole == 'editor' ||
      firebaseRole == 'admin' ||
      firebaseRole == 'superAdmin';
  bool get canModify =>
      (isAuthenticated && hasModificationAccess) || hasFirebaseWriteAccess;
  bool get isSuperAdmin =>
      session?.isSuperAdmin == true || firebaseRole == 'superAdmin';
  bool get isAdmin =>
      session?.isAdmin == true ||
      firebaseRole == 'admin' ||
      firebaseRole == 'superAdmin';
  bool get canSecurelyDeleteMember =>
      restoreStatus == SessionRestoreStatus.authenticated &&
      firebaseUid != null &&
      firebaseUid!.isNotEmpty &&
      (firebaseRole == 'admin' || firebaseRole == 'superAdmin');
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
        unawaited(
          ref.read(familyTreeProvider.notifier).stopRemoteFamilyTreeWatch(),
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
      await ref.read(familyTreeProvider.notifier).stopRemoteFamilyTreeWatch();
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
        await ref.read(familyTreeProvider.notifier).stopRemoteFamilyTreeWatch();
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
    final firebaseSession = await _tryFirebaseAccessCodeLogin(code);
    if (firebaseSession != null) {
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
      return true;
    }

    final data = await ref.read(familyTreeProvider.future);
    final service = ref.read(authCodeServiceProvider);
    final session = service.verifyCode(data, code);
    if (session == null) {
      return false;
    }
    state = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: session,
    );
    await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
    return true;
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
    if (firebaseAccessCodeService != null) {
      try {
        final firebaseSession = await firebaseAccessCodeService
            .signInWithAccessCode(trimmedCode);
        if (!firebaseSession.isEditor) {
          await logout();
          return false;
        }
        _applyFirebaseSession(firebaseSession);
        await _saveSessionMetadata(firebaseSession);
        await ref
            .read(familyTreeProvider.notifier)
            .startRemoteFamilyTreeWatch(
              includeActivityLog: firebaseSession.isAdmin,
            );
        await ref
            .read(familyTreeProvider.notifier)
            .addAuditLog(
              'modification_code_accepted',
              description: 'Accès modification autorisé via Firebase Auth.',
              actorRole: firebaseSession.role,
            );
        await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
        return true;
      } catch (_) {
        await ref
            .read(familyTreeProvider.notifier)
            .addAuditLog(
              'modification_code_refused',
              description: 'Code de modification incorrect.',
              actorRole: state.session?.role ?? 'viewer',
            );
        return false;
      }
    }

    final data = await ref.read(familyTreeProvider.future);
    final match = ref
        .read(modificationCodeServiceProvider)
        .validate(data, trimmedCode);
    await ref
        .read(familyTreeProvider.notifier)
        .addAuditLog(
          match == null
              ? 'modification_code_refused'
              : 'modification_code_accepted',
          description: match == null
              ? 'Code de modification incorrect.'
              : 'Code de modification accepté.',
          actorRole: state.session?.role ?? 'viewer',
        );
    if (match == null) return false;
    await ref
        .read(familyTreeProvider.notifier)
        .markModificationCodeUsed(match.code);
    state = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: state.session,
      hasModificationAccess: true,
      firebaseUid: state.firebaseUid,
      firebaseEmail: state.firebaseEmail,
      firebaseRole: state.firebaseRole,
      firebaseAuthMethod: state.firebaseAuthMethod,
    );
    return true;
  }

  Future<void> logout() async {
    await ref.read(familyTreeProvider.notifier).stopRemoteFamilyTreeWatch();
    final service = ref.read(firebaseAdminAuthServiceProvider);
    if (service != null && state.firebaseUid != null) {
      await service.signOut();
    }
    await ref.read(sessionStorageServiceProvider).clearSession();
    state = const AuthState(
      restoreStatus: SessionRestoreStatus.unauthenticated,
    );
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
