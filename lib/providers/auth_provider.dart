import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_code_service.dart';
import 'app_providers.dart';
import 'family_tree_provider.dart';

enum AuthMode { publicLimited, authenticated }

class AuthState {
  const AuthState({
    this.mode = AuthMode.publicLimited,
    this.session,
    this.hasModificationAccess = false,
  });

  final AuthMode mode;
  final AuthSession? session;
  final bool hasModificationAccess;

  bool get isAuthenticated => mode == AuthMode.authenticated && session != null;
  bool get canModify => isAuthenticated && hasModificationAccess;
  bool get isSuperAdmin => session?.isSuperAdmin == true;
  bool get isAdmin => session?.isAdmin == true;
}

final authSessionProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String code) async {
    final data = await ref.read(familyTreeProvider.future);
    final service = ref.read(authCodeServiceProvider);
    final session = service.verifyCode(data, code);
    if (session == null) {
      return false;
    }
    await service.saveLastCode(code);
    state = AuthState(mode: AuthMode.authenticated, session: session);
    return true;
  }

  Future<bool> unlockModification(String code) async {
    final data = await ref.read(familyTreeProvider.future);
    final match = ref.read(modificationCodeServiceProvider).validate(data, code);
    await ref.read(familyTreeProvider.notifier).addAuditLog(
          match == null ? 'modification_code_refused' : 'modification_code_accepted',
          description: match == null
              ? 'Code de modification incorrect.'
              : 'Code de modification accepté.',
          actorRole: state.session?.role ?? 'viewer',
        );
    if (match == null) return false;
    await ref.read(familyTreeProvider.notifier).markModificationCodeUsed(match.code);
    state = AuthState(
      mode: AuthMode.authenticated,
      session: state.session,
      hasModificationAccess: true,
    );
    return true;
  }

  void logout() => state = const AuthState();
}
