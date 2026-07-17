import 'package:ayivonpome/services/diagnostic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies local Firebase timeout as indeterminate reachability', () {
    expect(
      DiagnosticService.diagnosticMessageForCode('local-timeout'),
      'Réponse Firebase trop lente ou inaccessible',
    );
    expect(
      DiagnosticService.diagnosticMessageForCode('deadline-exceeded'),
      'Réponse Firebase trop lente ou inaccessible',
    );
  });

  test('classifies Firebase Auth and Firestore errors separately', () {
    expect(
      DiagnosticService.diagnosticMessageForCode('permission-denied'),
      startsWith('Accès refusé par les règles Firestore'),
    );
    expect(
      DiagnosticService.diagnosticMessageForCode('unauthenticated'),
      startsWith('Session absente ou expirée'),
    );
    expect(
      DiagnosticService.diagnosticMessageForCode('network-request-failed'),
      startsWith('Requête Firebase Auth bloquée'),
    );
    expect(
      DiagnosticService.diagnosticMessageForCode('failed-precondition'),
      startsWith('Configuration Firebase ou persistance indisponible'),
    );
  });
}
