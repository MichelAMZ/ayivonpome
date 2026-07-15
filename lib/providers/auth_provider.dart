import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_metadata.dart';
import '../services/auth_code_service.dart';
import '../services/firebase_admin_auth_service.dart';
import 'app_providers.dart';
import 'family_tree_provider.dart';

enum AuthMode { publicLimited, authenticated }

class AuthState {
  const AuthState({
    this.mode = AuthMode.publicLimited,
    this.session,
    this.hasModificationAccess = false,
    this.firebaseUid,
    this.firebaseEmail,
    this.firebaseRole,
    this.firebaseAuthMethod,
  });

  final AuthMode mode;
  final AuthSession? session;
  final bool hasModificationAccess;
  final String? firebaseUid;
  final String? firebaseEmail;
  final String? firebaseRole;
  final String? firebaseAuthMethod;

  bool get isAuthenticated => mode == AuthMode.authenticated && session != null;
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
}

final authSessionProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restoreSession);
    return const AuthState();
  }

  Future<bool> restoreSession() async {
    final service = ref.read(firebaseAccessCodeAuthServiceProvider);
    if (service == null) return false;
    try {
      final storedSession = await ref
          .read(sessionStorageServiceProvider)
          .readSession();
      if (storedSession == null) return false;
      final firebaseSession = await service.restoreCurrentSession();
      if (firebaseSession == null) return false;
      if (firebaseSession.uid != storedSession.uid ||
          !firebaseSession.familyIds.contains(storedSession.familyId)) {
        await ref.read(sessionStorageServiceProvider).clearSession();
        return false;
      }
      _applyFirebaseSession(firebaseSession);
      await ref.read(familyTreeProvider.notifier).runAutomaticDataCleanup();
      return true;
    } catch (_) {
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
    state = AuthState(mode: AuthMode.authenticated, session: session);
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
    final data = await ref.read(familyTreeProvider.future);
    final match = ref
        .read(modificationCodeServiceProvider)
        .validate(data, code);
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
      session: state.session,
      hasModificationAccess: true,
      firebaseUid: state.firebaseUid,
      firebaseEmail: state.firebaseEmail,
      firebaseRole: state.firebaseRole,
      firebaseAuthMethod: state.firebaseAuthMethod,
    );
    await _tryFirebaseAccessCodeLogin(code, requireEditor: true);
    return true;
  }

  Future<void> logout() async {
    final service = ref.read(firebaseAdminAuthServiceProvider);
    if (service != null && state.firebaseUid != null) {
      await service.signOut();
    }
    await ref.read(sessionStorageServiceProvider).clearSession();
    state = const AuthState();
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
      session: session,
      hasModificationAccess: firebaseSession.isEditor,
      firebaseUid: firebaseSession.uid,
      firebaseEmail: firebaseSession.email,
      firebaseRole: firebaseSession.role,
      firebaseAuthMethod: firebaseSession.authMethod,
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
}
