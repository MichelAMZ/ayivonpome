import 'dart:io';

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

  test('classifies the Firestore Web internal assertion', () {
    expect(
      DiagnosticService.diagnosticMessageForCode('firestore-internal-state'),
      contains('Etat interne Firestore Web invalide'),
    );
  });

  test('explains a family document permission refusal without guessing', () {
    final message = DiagnosticService.familyReadPermissionMessage(
      familyId: 'ayivon',
      connected: true,
      role: 'admin',
      familyIds: const ['ayivon'],
    );

    expect(message, contains('Impossible de lire families/ayivon'));
    expect(message, contains('✓ Utilisateur connecté'));
    expect(message, contains('✓ Rôle administrateur (admin)'));
    expect(message, contains('✓ familyIds contient ayivon'));
    expect(message, contains('champ isPublic indéterminés'));
    expect(message, contains('✗ Règle Firestore refusée'));
    expect(message, contains('Correction proposée'));
  });

  test('diagnostic write check no longer depends on Cloud Functions', () {
    final source = File(
      'lib/services/diagnostic_service.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('httpsCallable')));
    expect(source, isNot(contains('testFirestoreWrite')));
    expect(source, contains("collection('user_roles')"));
    expect(source, contains('Aucun document de diagnostic créé'));
  });
}
