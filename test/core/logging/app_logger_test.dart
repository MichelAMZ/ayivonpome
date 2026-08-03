import 'package:ayivonpome/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incident diagnostic identifies the step and removes secrets', () {
    AppLogger.startStep(BootstrapStep.publicFamilyLoading);

    final incident = AppLogger.capture(
      category: 'bootstrap',
      error: StateError(
        'email=user@example.com token=abc123 password=hunter2 code=9876',
      ),
      stackTrace: StackTrace.current,
    );
    final diagnostic = incident.technicalSummary();

    expect(incident.id, startsWith('AYV-BOOT-'));
    expect(diagnostic, contains('Étape: publicFamilyLoading'));
    expect(diagnostic, contains('Type: StateError'));
    expect(diagnostic, isNot(contains('user@example.com')));
    expect(diagnostic, isNot(contains('abc123')));
    expect(diagnostic, isNot(contains('hunter2')));
    expect(diagnostic, isNot(contains('9876')));
    expect(diagnostic, contains('<email>'));
    expect(diagnostic, contains('<masqué>'));
    expect(diagnostic, contains('Version: 1.0.0+1'));
    expect(diagnostic, contains('Firebase:'));
    expect(diagnostic, contains('Authentification:'));
    expect(diagnostic, contains('Langues navigateur:'));
    expect(diagnostic, contains('Navigateur:'));
    expect(diagnostic, contains('UserAgent:'));
    expect(diagnostic, contains('Dimensions écran:'));
    expect(diagnostic, contains('Route:'));
    expect(diagnostic, contains('Méthode:'));
    expect(diagnostic, contains('Fichier:'));
    expect(diagnostic, contains('Ligne:'));
    expect(diagnostic, contains('Projet Firebase:'));
    expect(diagnostic, contains('Pile:'));
    expect(diagnostic, isNot(contains('user@example.com')));
  });

  test('explicit asynchronous step is preserved in the incident', () {
    AppLogger.startStep(BootstrapStep.localeResolution);

    final incident = AppLogger.capture(
      category: 'bootstrap',
      error: StateError('empty public family'),
      stackTrace: StackTrace.current,
      step: BootstrapStep.publicFamilyLoading,
    );

    expect(incident.step, BootstrapStep.publicFamilyLoading);
    expect(AppInitializationFailure(incident).incident, same(incident));
  });
}
