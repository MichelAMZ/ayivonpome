import 'package:ayivonpome/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('staging build detection does not validate Firebase options', () {
    expect(AppEnvironment.isStagingBuild, isFalse);
  });

  test('staging refuse production, émulateur et projectId absent', () {
    for (final projectId in [
      '',
      AppEnvironment.productionProjectId,
      AppEnvironment.emulatorProjectId,
    ]) {
      expect(
        () =>
            AppEnvironment.validatePair(AppEnvironmentType.staging, projectId),
        throwsStateError,
      );
    }
  });

  test('production refuse un projectId staging', () {
    expect(
      () => AppEnvironment.validatePair(
        AppEnvironmentType.prod,
        'ayivon-staging',
      ),
      throwsStateError,
    );
    expect(
      () => AppEnvironment.validatePair(
        AppEnvironmentType.prod,
        AppEnvironment.productionProjectId,
      ),
      returnsNormally,
    );
  });
}
