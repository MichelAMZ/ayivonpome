enum AppEnvironmentType { dev, staging, prod }

class AppEnvironment {
  const AppEnvironment({
    required this.type,
    required this.projectId,
    required this.logsEnabled,
    required this.diagnosticsEnabled,
    required this.demoDataAllowed,
  });

  static const productionProjectId = 'ayivon-aziangbede';
  static const emulatorProjectId = 'demo-ayivon-staging';
  static const _buildEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  /// Safe to use while building the fallback UI, even when the complete
  /// Firebase staging configuration is missing or invalid.
  static bool get isStagingBuild =>
      _buildEnvironment.toLowerCase() == 'staging';

  factory AppEnvironment.fromEnvironment({String? appEnv, String? projectId}) {
    final name = appEnv ?? _buildEnvironment;
    final parsed = switch (name.toLowerCase()) {
      'dev' => AppEnvironmentType.dev,
      'staging' => AppEnvironmentType.staging,
      'prod' || 'production' => AppEnvironmentType.prod,
      _ => throw StateError('APP_ENV invalide: $name'),
    };
    final resolvedProjectId =
        projectId ?? const String.fromEnvironment('FIREBASE_PROJECT_ID');
    validatePair(parsed, resolvedProjectId);
    return AppEnvironment(
      type: parsed,
      projectId: resolvedProjectId,
      logsEnabled: parsed != AppEnvironmentType.prod,
      diagnosticsEnabled: parsed != AppEnvironmentType.prod,
      demoDataAllowed: parsed == AppEnvironmentType.dev,
    );
  }

  static void validatePair(AppEnvironmentType type, String projectId) {
    if (type == AppEnvironmentType.staging &&
        (projectId.isEmpty ||
            projectId == productionProjectId ||
            projectId == emulatorProjectId)) {
      throw StateError(
        'Un build staging exige un vrai projectId staging distinct.',
      );
    }
    if (type == AppEnvironmentType.prod &&
        projectId.isNotEmpty &&
        projectId != productionProjectId) {
      throw StateError('Un build production ne peut pas cibler $projectId.');
    }
  }

  final AppEnvironmentType type;
  final String projectId;
  final bool logsEnabled;
  final bool diagnosticsEnabled;
  final bool demoDataAllowed;

  bool get isStaging => type == AppEnvironmentType.staging;
  String get displayName => switch (type) {
    AppEnvironmentType.dev => 'Développement',
    AppEnvironmentType.staging => 'Préproduction',
    AppEnvironmentType.prod => 'Production',
  };
}
