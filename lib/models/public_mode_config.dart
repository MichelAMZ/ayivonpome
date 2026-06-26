class PublicModeConfig {
  const PublicModeConfig({
    this.enabled = true,
    this.visibleFields = const ['firstName', 'lastName', 'publicMapLocation'],
  });

  final bool enabled;
  final List<String> visibleFields;

  factory PublicModeConfig.fromJson(Map<String, dynamic> json) =>
      PublicModeConfig(
        enabled: json['enabled'] as bool? ?? true,
        visibleFields: List<String>.from(
          json['visibleFields'] as List? ??
              const ['firstName', 'lastName', 'publicMapLocation'],
        ),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'visibleFields': visibleFields,
      };
}
