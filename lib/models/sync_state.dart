class SyncSettings {
  const SyncSettings({
    this.storageMode = 'jsonAndDatabase',
    this.databaseEnabled = true,
    this.offlineModeEnabled = true,
    this.autoSyncOnReconnect = true,
    this.lastSyncAt = '',
    this.syncStatus = 'idle',
  });

  final String storageMode;
  final bool databaseEnabled;
  final bool offlineModeEnabled;
  final bool autoSyncOnReconnect;
  final String lastSyncAt;
  final String syncStatus;

  factory SyncSettings.fromJson(Map<String, dynamic> json) => SyncSettings(
    storageMode: json['storageMode'] as String? ?? 'jsonAndDatabase',
    databaseEnabled: json['databaseEnabled'] as bool? ?? true,
    offlineModeEnabled: json['offlineModeEnabled'] as bool? ?? true,
    autoSyncOnReconnect: json['autoSyncOnReconnect'] as bool? ?? true,
    lastSyncAt: json['lastSyncAt'] as String? ?? '',
    syncStatus: json['syncStatus'] as String? ?? 'idle',
  );

  Map<String, dynamic> toJson() => {
    'storageMode': storageMode,
    'databaseEnabled': databaseEnabled,
    'offlineModeEnabled': offlineModeEnabled,
    'autoSyncOnReconnect': autoSyncOnReconnect,
    'lastSyncAt': lastSyncAt,
    'syncStatus': syncStatus,
  };

  SyncSettings copyWith({
    String? storageMode,
    bool? databaseEnabled,
    bool? offlineModeEnabled,
    bool? autoSyncOnReconnect,
    String? lastSyncAt,
    String? syncStatus,
  }) {
    return SyncSettings(
      storageMode: storageMode ?? this.storageMode,
      databaseEnabled: databaseEnabled ?? this.databaseEnabled,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      autoSyncOnReconnect: autoSyncOnReconnect ?? this.autoSyncOnReconnect,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class PendingSyncItem {
  const PendingSyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payload = const {},
    this.createdAt = '',
    this.updatedAt = '',
    this.status = 'pending',
    this.retryCount = 0,
    this.updatedBy = '',
    this.lastError = '',
    this.lastErrorCode = '',
    this.lastAttemptAt = '',
    this.nextAttemptAt = '',
    this.requiresUserAction = false,
    this.dependsOnOperationIds = const [],
    this.errorType = '',
    this.stackTrace = '',
    this.sourceFile = '',
    this.sourceFunction = '',
    this.sourceLine,
    this.sourceColumn,
    this.routeName = '',
    this.appVersion = '',
    this.platform = '',
    this.locationPrecision = 'unavailable',
  });

  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String updatedAt;
  final String status;
  final int retryCount;
  final String updatedBy;
  final String lastError;
  final String lastErrorCode;
  final String lastAttemptAt;
  final String nextAttemptAt;
  final bool requiresUserAction;
  final List<String> dependsOnOperationIds;
  final String errorType;
  final String stackTrace;
  final String sourceFile;
  final String sourceFunction;
  final int? sourceLine;
  final int? sourceColumn;
  final String routeName;
  final String appVersion;
  final String platform;
  final String locationPrecision;

  factory PendingSyncItem.fromJson(
    Map<String, dynamic> json,
  ) => PendingSyncItem(
    id: json['id'] as String? ?? '',
    entityType: json['entityType'] as String? ?? '',
    entityId: json['entityId'] as String? ?? '',
    action: json['action'] as String? ?? '',
    payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    retryCount: json['retryCount'] as int? ?? json['attempts'] as int? ?? 0,
    updatedBy: json['updatedBy'] as String? ?? '',
    lastError:
        json['lastError'] as String? ?? json['errorMessage'] as String? ?? '',
    lastErrorCode: json['lastErrorCode'] as String? ?? '',
    lastAttemptAt: json['lastAttemptAt'] as String? ?? '',
    nextAttemptAt: json['nextAttemptAt'] as String? ?? '',
    requiresUserAction: json['requiresUserAction'] as bool? ?? false,
    dependsOnOperationIds: (json['dependsOnOperationIds'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(),
    errorType: json['errorType'] as String? ?? '',
    stackTrace: json['stackTrace'] as String? ?? '',
    sourceFile: json['sourceFile'] as String? ?? '',
    sourceFunction: json['sourceFunction'] as String? ?? '',
    sourceLine: json['sourceLine'] as int?,
    sourceColumn: json['sourceColumn'] as int?,
    routeName: json['routeName'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    platform: json['platform'] as String? ?? '',
    locationPrecision: json['locationPrecision'] as String? ?? 'unavailable',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'action': action,
    'payload': payload,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'status': status,
    'retryCount': retryCount,
    'attempts': retryCount,
    if (updatedBy.isNotEmpty) 'updatedBy': updatedBy,
    if (lastError.isNotEmpty) 'lastError': lastError,
    if (lastErrorCode.isNotEmpty) 'lastErrorCode': lastErrorCode,
    if (lastAttemptAt.isNotEmpty) 'lastAttemptAt': lastAttemptAt,
    if (nextAttemptAt.isNotEmpty) 'nextAttemptAt': nextAttemptAt,
    if (requiresUserAction) 'requiresUserAction': requiresUserAction,
    if (dependsOnOperationIds.isNotEmpty)
      'dependsOnOperationIds': dependsOnOperationIds,
    if (errorType.isNotEmpty) 'errorType': errorType,
    if (stackTrace.isNotEmpty) 'stackTrace': stackTrace,
    if (sourceFile.isNotEmpty) 'sourceFile': sourceFile,
    if (sourceFunction.isNotEmpty) 'sourceFunction': sourceFunction,
    if (sourceLine != null) 'sourceLine': sourceLine,
    if (sourceColumn != null) 'sourceColumn': sourceColumn,
    if (routeName.isNotEmpty) 'routeName': routeName,
    if (appVersion.isNotEmpty) 'appVersion': appVersion,
    if (platform.isNotEmpty) 'platform': platform,
    if (locationPrecision != 'unavailable')
      'locationPrecision': locationPrecision,
  };

  PendingSyncItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    Map<String, dynamic>? payload,
    String? createdAt,
    String? updatedAt,
    String? status,
    int? retryCount,
    String? updatedBy,
    String? lastError,
    String? lastErrorCode,
    String? lastAttemptAt,
    String? nextAttemptAt,
    bool? requiresUserAction,
    List<String>? dependsOnOperationIds,
    String? errorType,
    String? stackTrace,
    String? sourceFile,
    String? sourceFunction,
    int? sourceLine,
    int? sourceColumn,
    String? routeName,
    String? appVersion,
    String? platform,
    String? locationPrecision,
  }) {
    return PendingSyncItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      updatedBy: updatedBy ?? this.updatedBy,
      lastError: lastError ?? this.lastError,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      requiresUserAction: requiresUserAction ?? this.requiresUserAction,
      dependsOnOperationIds:
          dependsOnOperationIds ?? this.dependsOnOperationIds,
      errorType: errorType ?? this.errorType,
      stackTrace: stackTrace ?? this.stackTrace,
      sourceFile: sourceFile ?? this.sourceFile,
      sourceFunction: sourceFunction ?? this.sourceFunction,
      sourceLine: sourceLine ?? this.sourceLine,
      sourceColumn: sourceColumn ?? this.sourceColumn,
      routeName: routeName ?? this.routeName,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      locationPrecision: locationPrecision ?? this.locationPrecision,
    );
  }
}
