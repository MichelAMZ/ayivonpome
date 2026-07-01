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

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) =>
      PendingSyncItem(
        id: json['id'] as String? ?? '',
        entityType: json['entityType'] as String? ?? '',
        entityId: json['entityId'] as String? ?? '',
        action: json['action'] as String? ?? '',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        retryCount: json['retryCount'] as int? ?? 0,
        updatedBy: json['updatedBy'] as String? ?? '',
        lastError:
            json['lastError'] as String? ??
            json['errorMessage'] as String? ??
            '',
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
    if (updatedBy.isNotEmpty) 'updatedBy': updatedBy,
    if (lastError.isNotEmpty) 'lastError': lastError,
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
    );
  }
}
