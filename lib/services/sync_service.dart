import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/sync_state.dart';
import 'connectivity_service.dart';
import 'family_repository.dart';

class SyncService {
  const SyncService({
    required ConnectivityService connectivity,
    required FamilyRepository remoteRepository,
  }) : _connectivity = connectivity,
       _remoteRepository = remoteRepository;

  final ConnectivityService _connectivity;
  final FamilyRepository _remoteRepository;

  Future<FamilyTreeData> enqueueOrSync(
    FamilyTreeData data, {
    PendingSyncItem? operation,
  }) async {
    if (operation == null) return enqueueOrSyncMany(data);
    return enqueueOrSyncMany(data, operations: [operation]);
  }

  Future<FamilyTreeData> enqueueOrSyncMany(
    FamilyTreeData data, {
    List<PendingSyncItem> operations = const [],
  }) async {
    final storage = data.appSettings.storageSettings;
    if (!storage.remoteDatabaseEnabled ||
        storage.mode == 'jsonOnly' ||
        operations.isEmpty) {
      return data;
    }
    if (!storage.offlineQueueEnabled) {
      return _markStatus(data, 'idle');
    }
    final online = await _connectivity.isOnline;
    if (!online) {
      return _enqueueAll(data, operations, status: 'offline');
    }
    final audit = [...data.auditLog];
    final failed = <PendingSyncItem>[];
    try {
      for (final operation in operations) {
        try {
          await _send(operation);
          audit.add(
            _log(
              'sync_remote_success',
              operation.entityId,
              operation.entityType,
            ),
          );
        } catch (error) {
          failed.add(operation.copyWith(lastError: error.toString()));
        }
      }
      if (failed.isNotEmpty) {
        return _enqueueAll(
          data.copyWith(auditLog: audit),
          failed,
          status: 'pending',
        );
      }
      final now = DateTime.now().toIso8601String();
      final status = data.pendingSyncQueue.isEmpty ? 'synced' : 'pending';
      return data.copyWith(
        syncSettings: data.syncSettings.copyWith(
          syncStatus: status,
          lastSyncAt: now,
        ),
        appSettings: data.appSettings.copyWith(
          storageSettings: storage.copyWith(
            syncStatus: status,
            lastSyncAt: now,
          ),
        ),
        auditLog: audit,
      );
    } catch (error) {
      final withError = operations
          .map((operation) => operation.copyWith(lastError: error.toString()))
          .toList();
      return _enqueueAll(data, withError, status: 'pending');
    }
  }

  Future<FamilyTreeData> syncPendingQueue(FamilyTreeData data) async {
    final storage = data.appSettings.storageSettings;
    if (!storage.remoteDatabaseEnabled ||
        !storage.autoSyncOnReconnect ||
        data.pendingSyncQueue.isEmpty) {
      return data;
    }
    final online = await _connectivity.isOnline;
    if (!online) return _markStatus(data, 'offline');

    var working = _markStatus(data, 'syncing');
    final remaining = <PendingSyncItem>[];
    final audit = [...working.auditLog];
    var hadError = false;
    for (final item in working.pendingSyncQueue) {
      if (item.status == 'synced') continue;
      try {
        await _send(item);
        audit.add(_log('sync_queue_item_sent', item.entityId, item.entityType));
      } catch (error) {
        hadError = true;
        remaining.add(
          item.copyWith(
            status: 'failed',
            retryCount: item.retryCount + 1,
            lastError: error.toString(),
          ),
        );
        audit.add(
          _log('sync_queue_item_failed', item.entityId, item.entityType),
        );
      }
    }

    final now = DateTime.now().toIso8601String();
    final status = remaining.isEmpty
        ? 'synced'
        : hadError
        ? 'error'
        : 'pending';
    working = working.copyWith(
      pendingSyncQueue: remaining,
      syncSettings: working.syncSettings.copyWith(
        lastSyncAt: remaining.isEmpty ? now : working.syncSettings.lastSyncAt,
        syncStatus: status,
      ),
      appSettings: working.appSettings.copyWith(
        storageSettings: storage.copyWith(
          lastSyncAt: remaining.isEmpty ? now : storage.lastSyncAt,
          syncStatus: status,
        ),
      ),
      auditLog: audit,
    );
    return working;
  }

  PendingSyncItem personOperation({
    required Person person,
    required String action,
    required String updatedBy,
  }) {
    final now = DateTime.now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${DateTime.now().microsecondsSinceEpoch}',
      entityType: 'person',
      entityId: person.id,
      action: action,
      payload: person.toJson(),
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }

  PendingSyncItem deletePersonOperation({
    required String personId,
    required String updatedBy,
  }) {
    final now = DateTime.now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${DateTime.now().microsecondsSinceEpoch}',
      entityType: 'person',
      entityId: personId,
      action: 'delete',
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }

  PendingSyncItem marriageOperation({
    required MarriageRelation relation,
    required String action,
    required String updatedBy,
  }) {
    final now = DateTime.now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${DateTime.now().microsecondsSinceEpoch}',
      entityType: 'marriage',
      entityId: relation.id,
      action: action,
      payload: relation.toJson(),
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }

  PendingSyncItem familyLinkOperation({
    required FamilyLink link,
    required String action,
    required String updatedBy,
  }) {
    final now = DateTime.now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${DateTime.now().microsecondsSinceEpoch}',
      entityType: 'familyLink',
      entityId: link.id,
      action: action,
      payload: link.toJson(),
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }

  Future<void> _send(PendingSyncItem item) async {
    if (item.entityType == 'marriage') {
      if (item.action == 'delete') {
        await _remoteRepository.deleteMarriage(item.entityId);
        return;
      }
      final relation = MarriageRelation.fromJson(item.payload);
      if (item.action == 'create' || item.action == 'restore') {
        await _remoteRepository.createMarriage(relation);
      } else {
        await _remoteRepository.updateMarriage(relation);
      }
      return;
    }
    if (item.entityType == 'familyLink') {
      final link = FamilyLink.fromJson(item.payload);
      if (item.action == 'create' || item.action == 'restore') {
        await _remoteRepository.createFamilyLink(link);
      } else {
        await _remoteRepository.updateFamilyLink(link);
      }
      return;
    }
    if (item.entityType != 'person') return;
    if (item.action == 'delete') {
      await _remoteRepository.deletePerson(item.entityId);
      return;
    }
    final person = Person.fromJson(item.payload);
    if (item.action == 'create' || item.action == 'restore') {
      await _remoteRepository.createPerson(person);
    } else {
      await _remoteRepository.updatePerson(person);
    }
  }

  FamilyTreeData _enqueueAll(
    FamilyTreeData data,
    List<PendingSyncItem> operations, {
    required String status,
  }) {
    var queue = [...data.pendingSyncQueue];
    final audit = [...data.auditLog];
    for (final operation in operations) {
      queue = [
        ...queue.where(
          (item) =>
              item.entityType != operation.entityType ||
              item.entityId != operation.entityId ||
              item.action != operation.action,
        ),
        operation.copyWith(status: 'pending'),
      ];
      audit.add(_log('sync_queued', operation.entityId, operation.entityType));
    }
    return data.copyWith(
      pendingSyncQueue: queue,
      syncSettings: data.syncSettings.copyWith(syncStatus: status),
      appSettings: data.appSettings.copyWith(
        storageSettings: data.appSettings.storageSettings.copyWith(
          syncStatus: status,
        ),
      ),
      auditLog: audit,
    );
  }

  FamilyTreeData _markStatus(FamilyTreeData data, String status) {
    return data.copyWith(
      syncSettings: data.syncSettings.copyWith(syncStatus: status),
      appSettings: data.appSettings.copyWith(
        storageSettings: data.appSettings.storageSettings.copyWith(
          syncStatus: status,
        ),
      ),
    );
  }

  AuditLog _log(String action, String entityId, String entityType) {
    return AuditLog(
      id: 'log${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now().toIso8601String(),
      action: action,
      personId: entityType == 'person' ? entityId : '',
      description: '$entityType:$entityId',
    );
  }
}
