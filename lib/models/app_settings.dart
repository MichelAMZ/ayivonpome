class AppSettings {
  const AppSettings({
    this.applicationTitle = 'FamilyTreeApp',
    this.applicationSubtitle = '',
    this.showApplicationSubtitle = false,
    this.officialFamilyName = '',
    this.treeSettings = const TreeViewSettings(),
  });

  final String applicationTitle;
  final String applicationSubtitle;
  final bool showApplicationSubtitle;
  final String officialFamilyName;
  final TreeViewSettings treeSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    applicationTitle: json['applicationTitle'] as String? ?? 'FamilyTreeApp',
    applicationSubtitle: json['applicationSubtitle'] as String? ?? '',
    showApplicationSubtitle: json['showApplicationSubtitle'] as bool? ?? false,
    officialFamilyName: json['officialFamilyName'] as String? ?? '',
    treeSettings: TreeViewSettings.fromJson(
      Map<String, dynamic>.from(json['treeSettings'] as Map? ?? const {}),
    ),
  );

  Map<String, dynamic> toJson() => {
    'applicationTitle': applicationTitle,
    'applicationSubtitle': applicationSubtitle,
    'showApplicationSubtitle': showApplicationSubtitle,
    'officialFamilyName': officialFamilyName,
    'treeSettings': treeSettings.toJson(),
  };

  AppSettings copyWith({
    String? applicationTitle,
    String? applicationSubtitle,
    bool? showApplicationSubtitle,
    String? officialFamilyName,
    TreeViewSettings? treeSettings,
  }) {
    return AppSettings(
      applicationTitle: applicationTitle ?? this.applicationTitle,
      applicationSubtitle: applicationSubtitle ?? this.applicationSubtitle,
      showApplicationSubtitle:
          showApplicationSubtitle ?? this.showApplicationSubtitle,
      officialFamilyName: officialFamilyName ?? this.officialFamilyName,
      treeSettings: treeSettings ?? this.treeSettings,
    );
  }
}

class TreeViewSettings {
  const TreeViewSettings({
    this.initialZoom = 0.60,
    this.minZoom = 0.20,
    this.maxZoom = 3.00,
    this.rememberLastZoom = true,
  });

  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool rememberLastZoom;

  factory TreeViewSettings.fromJson(Map<String, dynamic> json) =>
      TreeViewSettings(
        initialZoom: (json['initialZoom'] as num?)?.toDouble() ?? 0.60,
        minZoom: (json['minZoom'] as num?)?.toDouble() ?? 0.20,
        maxZoom: (json['maxZoom'] as num?)?.toDouble() ?? 3.00,
        rememberLastZoom: json['rememberLastZoom'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'initialZoom': initialZoom,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'rememberLastZoom': rememberLastZoom,
  };

  TreeViewSettings copyWith({
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    bool? rememberLastZoom,
  }) {
    return TreeViewSettings(
      initialZoom: initialZoom ?? this.initialZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      rememberLastZoom: rememberLastZoom ?? this.rememberLastZoom,
    );
  }
}
