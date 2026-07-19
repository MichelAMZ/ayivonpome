import 'package:ayivonpome/widgets/modification_code_required_dialog.dart';
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
        'Code incorrect ou accès non autorisé.',
      );
      expect(
        ModificationAuthorizationStep.savedLocally.statusLabel,
        contains('Synchronisation en attente'),
      );
    },
  );
}
