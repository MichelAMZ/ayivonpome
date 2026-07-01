class AppSettings {
  const AppSettings({
    this.applicationTitle = 'FamilyTreeApp',
    this.applicationSubtitle = '',
    this.showApplicationSubtitle = false,
    this.officialFamilyName = '',
    this.storageSettings = const StorageSettings(),
    this.treeSettings = const TreeViewSettings(),
    this.languageSettings = const LanguageSettings(),
    this.tutorialSettings = const TutorialSettings(),
  });

  final String applicationTitle;
  final String applicationSubtitle;
  final bool showApplicationSubtitle;
  final String officialFamilyName;
  final StorageSettings storageSettings;
  final TreeViewSettings treeSettings;
  final LanguageSettings languageSettings;
  final TutorialSettings tutorialSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    applicationTitle: json['applicationTitle'] as String? ?? 'FamilyTreeApp',
    applicationSubtitle: json['applicationSubtitle'] as String? ?? '',
    showApplicationSubtitle: json['showApplicationSubtitle'] as bool? ?? false,
    officialFamilyName: json['officialFamilyName'] as String? ?? '',
    storageSettings: StorageSettings.fromJson(
      Map<String, dynamic>.from(json['storageSettings'] as Map? ?? const {}),
    ),
    treeSettings: TreeViewSettings.fromJson(
      Map<String, dynamic>.from(json['treeSettings'] as Map? ?? const {}),
    ),
    languageSettings: LanguageSettings.fromJson(
      Map<String, dynamic>.from(json['languageSettings'] as Map? ?? const {}),
    ),
    tutorialSettings: TutorialSettings.fromJson(
      Map<String, dynamic>.from(json['tutorialSettings'] as Map? ?? const {}),
    ),
  );

  Map<String, dynamic> toJson() => {
    'applicationTitle': applicationTitle,
    'applicationSubtitle': applicationSubtitle,
    'showApplicationSubtitle': showApplicationSubtitle,
    'officialFamilyName': officialFamilyName,
    'storageSettings': storageSettings.toJson(),
    'treeSettings': treeSettings.toJson(),
    'languageSettings': languageSettings.toJson(),
    'tutorialSettings': tutorialSettings.toJson(),
  };

  AppSettings copyWith({
    String? applicationTitle,
    String? applicationSubtitle,
    bool? showApplicationSubtitle,
    String? officialFamilyName,
    StorageSettings? storageSettings,
    TreeViewSettings? treeSettings,
    LanguageSettings? languageSettings,
    TutorialSettings? tutorialSettings,
  }) {
    return AppSettings(
      applicationTitle: applicationTitle ?? this.applicationTitle,
      applicationSubtitle: applicationSubtitle ?? this.applicationSubtitle,
      showApplicationSubtitle:
          showApplicationSubtitle ?? this.showApplicationSubtitle,
      officialFamilyName: officialFamilyName ?? this.officialFamilyName,
      storageSettings: storageSettings ?? this.storageSettings,
      treeSettings: treeSettings ?? this.treeSettings,
      languageSettings: languageSettings ?? this.languageSettings,
      tutorialSettings: tutorialSettings ?? this.tutorialSettings,
    );
  }
}

class StorageSettings {
  const StorageSettings({
    this.mode = 'hybrid',
    this.localJsonEnabled = true,
    this.remoteDatabaseEnabled = true,
    this.offlineQueueEnabled = true,
    this.autoSyncOnReconnect = true,
    this.lastSyncAt = '',
    this.syncStatus = 'idle',
  });

  final String mode;
  final bool localJsonEnabled;
  final bool remoteDatabaseEnabled;
  final bool offlineQueueEnabled;
  final bool autoSyncOnReconnect;
  final String lastSyncAt;
  final String syncStatus;

  factory StorageSettings.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String? ?? 'hybrid';
    return StorageSettings(
      mode: const {'jsonOnly', 'databaseOnly', 'hybrid'}.contains(mode)
          ? mode
          : 'hybrid',
      localJsonEnabled: json['localJsonEnabled'] as bool? ?? true,
      remoteDatabaseEnabled: json['remoteDatabaseEnabled'] as bool? ?? true,
      offlineQueueEnabled: json['offlineQueueEnabled'] as bool? ?? true,
      autoSyncOnReconnect: json['autoSyncOnReconnect'] as bool? ?? true,
      lastSyncAt: json['lastSyncAt'] as String? ?? '',
      syncStatus: json['syncStatus'] as String? ?? 'idle',
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'localJsonEnabled': localJsonEnabled,
    'remoteDatabaseEnabled': remoteDatabaseEnabled,
    'offlineQueueEnabled': offlineQueueEnabled,
    'autoSyncOnReconnect': autoSyncOnReconnect,
    'lastSyncAt': lastSyncAt,
    'syncStatus': syncStatus,
  };

  StorageSettings copyWith({
    String? mode,
    bool? localJsonEnabled,
    bool? remoteDatabaseEnabled,
    bool? offlineQueueEnabled,
    bool? autoSyncOnReconnect,
    String? lastSyncAt,
    String? syncStatus,
  }) {
    return StorageSettings(
      mode: mode ?? this.mode,
      localJsonEnabled: localJsonEnabled ?? this.localJsonEnabled,
      remoteDatabaseEnabled:
          remoteDatabaseEnabled ?? this.remoteDatabaseEnabled,
      offlineQueueEnabled: offlineQueueEnabled ?? this.offlineQueueEnabled,
      autoSyncOnReconnect: autoSyncOnReconnect ?? this.autoSyncOnReconnect,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class TutorialSettings {
  const TutorialSettings({
    this.showTutorialOnFirstLaunch = true,
    this.tutorialAlreadySeen = false,
    this.showFloatingHelpButton = true,
    this.buttonPosition = 'bottomRight',
  });

  final bool showTutorialOnFirstLaunch;
  final bool tutorialAlreadySeen;
  final bool showFloatingHelpButton;
  final String buttonPosition;

  factory TutorialSettings.fromJson(Map<String, dynamic> json) =>
      TutorialSettings(
        showTutorialOnFirstLaunch:
            json['showTutorialOnFirstLaunch'] as bool? ?? true,
        tutorialAlreadySeen: json['tutorialAlreadySeen'] as bool? ?? false,
        showFloatingHelpButton: json['showFloatingHelpButton'] as bool? ?? true,
        buttonPosition: json['buttonPosition'] as String? ?? 'bottomRight',
      );

  Map<String, dynamic> toJson() => {
    'showTutorialOnFirstLaunch': showTutorialOnFirstLaunch,
    'tutorialAlreadySeen': tutorialAlreadySeen,
    'showFloatingHelpButton': showFloatingHelpButton,
    'buttonPosition': buttonPosition,
  };

  TutorialSettings copyWith({
    bool? showTutorialOnFirstLaunch,
    bool? tutorialAlreadySeen,
    bool? showFloatingHelpButton,
    String? buttonPosition,
  }) {
    return TutorialSettings(
      showTutorialOnFirstLaunch:
          showTutorialOnFirstLaunch ?? this.showTutorialOnFirstLaunch,
      tutorialAlreadySeen: tutorialAlreadySeen ?? this.tutorialAlreadySeen,
      showFloatingHelpButton:
          showFloatingHelpButton ?? this.showFloatingHelpButton,
      buttonPosition: buttonPosition ?? this.buttonPosition,
    );
  }
}

class LanguageSettings {
  const LanguageSettings({
    this.autoDetectByCountry = true,
    this.manualLocale = '',
    this.currentLocale = '',
    this.supportedLocales = const ['fr', 'en', 'es', 'pt', 'de'],
  });

  final bool autoDetectByCountry;
  final String manualLocale;
  final String currentLocale;
  final List<String> supportedLocales;

  factory LanguageSettings.fromJson(Map<String, dynamic> json) =>
      LanguageSettings(
        autoDetectByCountry: json['autoDetectByCountry'] as bool? ?? true,
        manualLocale: json['manualLocale'] as String? ?? '',
        currentLocale: json['currentLocale'] as String? ?? '',
        supportedLocales:
            (json['supportedLocales'] as List?)
                ?.map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList() ??
            const ['fr', 'en', 'es', 'pt', 'de'],
      );

  Map<String, dynamic> toJson() => {
    'autoDetectByCountry': autoDetectByCountry,
    'manualLocale': manualLocale,
    'currentLocale': currentLocale,
    'supportedLocales': supportedLocales,
  };

  LanguageSettings copyWith({
    bool? autoDetectByCountry,
    String? manualLocale,
    String? currentLocale,
    List<String>? supportedLocales,
  }) {
    return LanguageSettings(
      autoDetectByCountry: autoDetectByCountry ?? this.autoDetectByCountry,
      manualLocale: manualLocale ?? this.manualLocale,
      currentLocale: currentLocale ?? this.currentLocale,
      supportedLocales: supportedLocales ?? this.supportedLocales,
    );
  }
}

class TreeViewSettings {
  const TreeViewSettings({
    this.initialZoom = 0.60,
    this.minZoom = 0.40,
    this.maxZoom = 1.20,
    this.resetViewOnStartup = true,
    this.rememberLastZoom = false,
    this.rememberLastPosition = false,
    this.showMembersCounter = true,
    this.showGenerationBadges = true,
  });

  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool resetViewOnStartup;
  final bool rememberLastZoom;
  final bool rememberLastPosition;
  final bool showMembersCounter;
  final bool showGenerationBadges;

  factory TreeViewSettings.fromJson(Map<String, dynamic> json) =>
      TreeViewSettings(
        initialZoom: (json['initialZoom'] as num?)?.toDouble() ?? 0.60,
        minZoom: (json['minZoom'] as num?)?.toDouble() ?? 0.40,
        maxZoom: (json['maxZoom'] as num?)?.toDouble() ?? 1.20,
        resetViewOnStartup: json['resetViewOnStartup'] as bool? ?? true,
        rememberLastZoom: json['rememberLastZoom'] as bool? ?? false,
        rememberLastPosition: json['rememberLastPosition'] as bool? ?? false,
        showMembersCounter: json['showMembersCounter'] as bool? ?? true,
        showGenerationBadges: json['showGenerationBadges'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'initialZoom': initialZoom,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'resetViewOnStartup': resetViewOnStartup,
    'rememberLastZoom': rememberLastZoom,
    'rememberLastPosition': rememberLastPosition,
    'showMembersCounter': showMembersCounter,
    'showGenerationBadges': showGenerationBadges,
  };

  TreeViewSettings copyWith({
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    bool? resetViewOnStartup,
    bool? rememberLastZoom,
    bool? rememberLastPosition,
    bool? showMembersCounter,
    bool? showGenerationBadges,
  }) {
    return TreeViewSettings(
      initialZoom: initialZoom ?? this.initialZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      resetViewOnStartup: resetViewOnStartup ?? this.resetViewOnStartup,
      rememberLastZoom: rememberLastZoom ?? this.rememberLastZoom,
      rememberLastPosition: rememberLastPosition ?? this.rememberLastPosition,
      showMembersCounter: showMembersCounter ?? this.showMembersCounter,
      showGenerationBadges: showGenerationBadges ?? this.showGenerationBadges,
    );
  }
}
