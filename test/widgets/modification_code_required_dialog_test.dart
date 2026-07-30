import 'package:ayivonpome/widgets/modification_code_required_dialog.dart';
import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authorization processing steps expose visible progress labels', () {
    const processingSteps = [
      ModificationAuthorizationStep.preparingFirebase,
      ModificationAuthorizationStep.verifyingCode,
      ModificationAuthorizationStep.restoringAuthentication,
      ModificationAuthorizationStep.checkingPermissions,
      ModificationAuthorizationStep.synchronizing,
    ];

    for (final step in processingSteps) {
      expect(step.isProcessing, isTrue);
      expect(step.buttonLabel, isNotEmpty);
      expect(step.statusLabel, isNotEmpty);
    }
  });

  test(
    'authorization terminal states stop processing and keep clear messages',
    () {
      expect(ModificationAuthorizationStep.idle.isProcessing, isFalse);
      expect(ModificationAuthorizationStep.failed.isProcessing, isFalse);
      expect(ModificationAuthorizationStep.savedLocally.isProcessing, isFalse);
      expect(
        ModificationAuthorizationStep.failed.statusLabel,
        'Code administrateur incorrect. Vérifiez le code puis réessayez.',
      );
      expect(
        ModificationAuthorizationStep.savedLocally.statusLabel,
        contains('Synchronisation en attente'),
      );
    },
  );

  test('keeps the administration authorization mode inside KPI', () {
    const admin = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseAuthMethod: 'password',
    );
    const editor = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'editor'),
      firebaseUid: 'editor-uid',
      firebaseRole: 'editor',
      firebaseAuthMethod: 'accessCode',
    );

    expect(
      modificationAuthorizationModeFor(admin),
      ModificationAuthorizationMode.administration,
    );
    expect(
      modificationAuthorizationModeFor(editor),
      ModificationAuthorizationMode.modification,
    );
  });
}
