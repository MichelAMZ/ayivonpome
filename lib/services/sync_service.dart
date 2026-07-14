import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/sync_diagnostic.dart';
import '../models/sync_incident.dart';
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
    await _logSyncStart(data, operations.length);
    try {
      for (final operation in operations) {
        _logOperation(operation, data.mainFamilyCode);
        try {
          await _send(operation);
          audit.add(
            _log(
              'sync_remote_success',
              operation.entityId,
              operation.entityType,
            ),
          );
        } on FirebaseException catch (error, stackTrace) {
          final lastError = _logFirebaseFailure(
            operation,
            data.mainFamilyCode,
            error,
            stackTrace,
          );
          await _reportIncident(operation, data.mainFamilyCode, lastError);
          failed.add(operation.copyWith(lastError: lastError));
        } catch (error, stackTrace) {
          final lastError = _logGenericFailure(
            operation,
            data.mainFamilyCode,
            error,
            stackTrace,
          );
          await _reportIncident(operation, data.mainFamilyCode, lastError);
          failed.add(operation.copyWith(lastError: lastError));
        }
      }
      if (failed.isNotEmpty) {
        return _enqueueAll(
          data.copyWith(auditLog: audit),
          failed,
          status: 'pending',
          operationStatus: 'failed',
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
    } on FirebaseException catch (error, stackTrace) {
      final withError = operations
          .map(
            (operation) => operation.copyWith(
              lastError: _logFirebaseFailure(
                operation,
                data.mainFamilyCode,
                error,
                stackTrace,
              ),
            ),
          )
          .toList();
      return _enqueueAll(
        data,
        withError,
        status: 'pending',
        operationStatus: 'failed',
      );
    } catch (error, stackTrace) {
      final withError = operations
          .map(
            (operation) => operation.copyWith(
              lastError: _logGenericFailure(
                operation,
                data.mainFamilyCode,
                error,
                stackTrace,
              ),
            ),
          )
          .toList();
      return _enqueueAll(
        data,
        withError,
        status: 'pending',
        operationStatus: 'failed',
      );
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
    await _logSyncStart(working, working.pendingSyncQueue.length);
    final remaining = <PendingSyncItem>[];
    final audit = [...working.auditLog];
    var hadError = false;
    for (final item in working.pendingSyncQueue) {
      if (item.status == 'synced' || item.status == 'resolved') continue;
      _logOperation(item, working.mainFamilyCode);
      try {
        await _send(item);
        audit.add(_log('sync_queue_item_sent', item.entityId, item.entityType));
      } on FirebaseException catch (error, stackTrace) {
        final lastError = _logFirebaseFailure(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
        );
        await _reportIncident(item, working.mainFamilyCode, lastError);
        hadError = true;
        remaining.add(
          item.copyWith(
            status: 'failed',
            retryCount: item.retryCount + 1,
            lastError: lastError,
          ),
        );
        audit.add(
          _log('sync_queue_item_failed', item.entityId, item.entityType),
        );
      } catch (error, stackTrace) {
        final lastError = _logGenericFailure(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
        );
        await _reportIncident(item, working.mainFamilyCode, lastError);
        hadError = true;
        remaining.add(
          item.copyWith(
            status: 'failed',
            retryCount: item.retryCount + 1,
            lastError: lastError,
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
        ? 'pending'
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
    String operationStatus = 'pending',
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
        operation.copyWith(status: operationStatus),
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

  Future<void> _logSyncStart(FamilyTreeData data, int operationCount) async {
    debugPrint(
      'SYNC START familyId=${data.mainFamilyCode} operations=$operationCount',
    );
    if (Firebase.apps.isEmpty) {
      debugPrint('AUTH UID: <firebase-not-initialized>');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    debugPrint('AUTH UID: ${user?.uid}');
    debugPrint('AUTH EMAIL: ${user?.email}');
    debugPrint('AUTH ANONYMOUS: ${user?.isAnonymous}');
    if (user == null) return;

    try {
      final role = await FirebaseFirestore.instance
          .collection('user_roles')
          .doc(user.uid)
          .get();
      final data = role.data();
      debugPrint('AUTH ROLE EXISTS: ${role.exists}');
      debugPrint('AUTH ROLE: ${data?['role']}');
      debugPrint('AUTH ACTIVE: ${data?['active']}');
      debugPrint('AUTH FAMILY_IDS: ${data?['familyIds']}');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('AUTH ROLE FIREBASE CODE: ${error.code}');
      debugPrint('AUTH ROLE FIREBASE MESSAGE: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('AUTH ROLE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _logOperation(PendingSyncItem item, String familyId) {
    final diagnostic = SyncOperationDiagnostic.fromItem(
      item,
      fallbackFamilyId: familyId,
    );
    debugPrint(
      'SYNC OPERATION: ${DateTime.now().toIso8601String()} '
      '${diagnostic.operationSummary}',
    );
  }

  String _logFirebaseFailure(
    PendingSyncItem item,
    String familyId,
    FirebaseException error,
    StackTrace stackTrace,
  ) {
    final diagnostic = SyncOperationDiagnostic.fromItem(
      item,
      fallbackFamilyId: familyId,
      firebaseException: error,
    );
    debugPrint('FIREBASE CODE: ${error.code}');
    debugPrint('FIREBASE MESSAGE: ${error.message}');
    debugPrint(
      'SYNC FAILED: ${DateTime.now().toIso8601String()} '
      '${diagnostic.operationSummary}',
    );
    debugPrintStack(stackTrace: stackTrace);
    return diagnostic.failureSummary;
  }

  String _logGenericFailure(
    PendingSyncItem item,
    String familyId,
    Object error,
    StackTrace stackTrace,
  ) {
    final diagnostic = SyncOperationDiagnostic.fromItem(
      item,
      fallbackFamilyId: familyId,
    );
    debugPrint('SYNC ERROR: $error');
    debugPrint(
      'SYNC FAILED: ${DateTime.now().toIso8601String()} '
      '${diagnostic.operationSummary}',
    );
    debugPrintStack(stackTrace: stackTrace);
    final message = error.toString();
    if (message.contains('Dart exception thrown from converted Future')) {
      return 'sync-error sur ${diagnostic.target} - erreur Firestore Web '
          'pendant ${diagnostic.action}. Relancez la synchronisation pour '
          'remplacer ce message générique par le code Firebase exact.';
    }
    return 'sync-error sur ${diagnostic.target} - $message';
  }

  Future<void> _reportIncident(
    PendingSyncItem item,
    String familyId,
    String lastError,
  ) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final incident = SyncIncident.fromPendingItem(
        item.copyWith(lastError: lastError, retryCount: item.retryCount + 1),
        familyId: familyId,
        userId: user?.uid ?? '',
        userEmail: user?.email ?? '',
      );
      await _remoteRepository.upsertSyncIncident(incident);
    } catch (error, stackTrace) {
      debugPrint('SYNC INCIDENT REPORT SKIPPED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
