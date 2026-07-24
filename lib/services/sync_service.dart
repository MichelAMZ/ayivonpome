import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/member_save_result.dart';
import '../models/person.dart';
import '../models/sync_diagnostic.dart';
import '../models/sync_incident.dart';
import '../models/sync_state.dart';
import '../models/server_operation.dart';
import '../data/firestore/firestore_document_mapper.dart';
import 'connectivity_service.dart';
import 'family_repository.dart';
import 'incident_reporter.dart';
import 'server_operation_service.dart';

class SyncService {
  SyncService({
    required ConnectivityService connectivity,
    required FamilyRepository remoteRepository,
    IncidentReporter? incidentReporter,
    DateTime Function()? nowProvider,
    Random? random,
    ServerOperationGateway? serverOperationService,
    bool serverOperationQueueEnabled = false,
  }) : _connectivity = connectivity,
       _remoteRepository = remoteRepository,
       _nowProvider = nowProvider,
       _random = random ?? Random(),
       _serverOperationService = serverOperationService,
       _serverOperationQueueEnabled = serverOperationQueueEnabled,
       _incidentReporter =
           incidentReporter ?? IncidentReporter(remoteRepository);

  final ConnectivityService _connectivity;
  final FamilyRepository _remoteRepository;
  final IncidentReporter _incidentReporter;
  final DateTime Function()? _nowProvider;
  final Random _random;
  final ServerOperationGateway? _serverOperationService;
  final bool _serverOperationQueueEnabled;
  static const int maxLocalAttempts = 8;
  Future<FamilyTreeData>? _runningSync;

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
    if (_serverOperationQueueEnabled && _serverOperationService != null) {
      return _submitOperations(data, operations);
    }
    final online = await _connectivity.isOnline;
    if (!online) {
      return _enqueueAll(
        data,
        operations.map((operation) => _scheduleRetry(operation)).toList(),
        status: 'offline',
        operationStatus: 'retryScheduled',
      );
    }
    final audit = [...data.auditLog];
    final failed = <PendingSyncItem>[];
    final succeeded = <PendingSyncItem>[];
    await _logSyncStart(data, operations.length);
    try {
      for (final operation in operations) {
        _logOperation(operation, data.mainFamilyCode);
        try {
          debugPrint('SYNC SEND START operationId=${operation.id}');
          await _send(operation, data);
          debugPrint('SYNC SEND SUCCESS operationId=${operation.id}');
          succeeded.add(operation);
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
          await _reportIncident(
            operation,
            data.mainFamilyCode,
            error,
            stackTrace,
            sourceFunction: 'enqueueOrSyncMany',
          );
          failed.add(
            _withFailureDiagnostic(
              operation,
              data.mainFamilyCode,
              lastError,
              error,
              stackTrace,
              sourceFunction: 'enqueueOrSyncMany',
              retryCount: operation.retryCount + 1,
            ),
          );
        } catch (error, stackTrace) {
          final lastError = _logGenericFailure(
            operation,
            data.mainFamilyCode,
            error,
            stackTrace,
          );
          await _reportIncident(
            operation,
            data.mainFamilyCode,
            error,
            stackTrace,
            sourceFunction: 'enqueueOrSyncMany',
          );
          failed.add(
            _withFailureDiagnostic(
              operation,
              data.mainFamilyCode,
              lastError,
              error,
              stackTrace,
              sourceFunction: 'enqueueOrSyncMany',
              retryCount: operation.retryCount + 1,
            ),
          );
        }
      }
      if (failed.isNotEmpty) {
        return _enqueueAll(
          data.copyWith(
            auditLog: audit,
            pendingSyncQueue: _removeMatchingOperations(
              data.pendingSyncQueue,
              succeeded,
            ),
          ),
          failed,
          status: 'pending',
          operationStatus: 'retryScheduled',
        );
      }
      final now = _now().toIso8601String();
      final pendingQueue = _removeMatchingOperations(
        data.pendingSyncQueue,
        succeeded,
      );
      final status = pendingQueue.isEmpty ? 'synced' : 'pending';
      return data.copyWith(
        pendingSyncQueue: pendingQueue,
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
      final withError = operations.map((operation) {
        final lastError = _logFirebaseFailure(
          operation,
          data.mainFamilyCode,
          error,
          stackTrace,
        );
        return _withFailureDiagnostic(
          operation,
          data.mainFamilyCode,
          lastError,
          error,
          stackTrace,
          sourceFunction: 'enqueueOrSyncMany',
        );
      }).toList();
      return _enqueueAll(
        data,
        withError,
        status: 'pending',
        operationStatus: 'retryScheduled',
      );
    } catch (error, stackTrace) {
      final withError = operations.map((operation) {
        final lastError = _logGenericFailure(
          operation,
          data.mainFamilyCode,
          error,
          stackTrace,
        );
        return _withFailureDiagnostic(
          operation,
          data.mainFamilyCode,
          lastError,
          error,
          stackTrace,
          sourceFunction: 'enqueueOrSyncMany',
        );
      }).toList();
      return _enqueueAll(
        data,
        withError,
        status: 'pending',
        operationStatus: 'retryScheduled',
      );
    }
  }

  Future<FamilyTreeData> syncPendingQueue(
    FamilyTreeData data, {
    bool force = false,
  }) {
    final current = _runningSync;
    if (current != null) return current;
    final run = _syncPendingQueue(data, force: force);
    _runningSync = run;
    return run.whenComplete(() {
      if (identical(_runningSync, run)) {
        _runningSync = null;
      }
    });
  }

  Future<({FamilyTreeData data, MemberSaveResult result})>
  attemptCurrentOperations(
    FamilyTreeData data, {
    required List<PendingSyncItem> operations,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final operationIds = operations
        .map((item) => item.id)
        .toList(growable: false);
    if (operations.isEmpty) {
      return (
        data: data,
        result: const MemberSaveResult(
          localSaved: true,
          remoteStatus: RemoteSaveStatus.confirmed,
        ),
      );
    }
    final deadline = DateTime.now().add(timeout);
    var latest = data;
    try {
      latest = await enqueueOrSyncMany(
        data,
        operations: operations,
      ).timeout(timeout);
      if (_serverOperationQueueEnabled && _serverOperationService != null) {
        final remainingTime = deadline.difference(DateTime.now());
        if (remainingTime <= Duration.zero) throw TimeoutException('sync');
        latest = await _awaitCurrentServerOperations(
          latest,
          operationIds,
          timeout: remainingTime,
        );
      }
      return (
        data: latest,
        result: resultForOperationIds(latest, operationIds),
      );
    } on TimeoutException {
      return (
        data: latest,
        result: MemberSaveResult(
          localSaved: true,
          remoteStatus: RemoteSaveStatus.timedOut,
          operationIds: operationIds,
          firebaseCode: 'deadline-exceeded',
          lastError: 'La tentative Firestore a dépassé le délai imparti.',
        ),
      );
    }
  }

  Future<FamilyTreeData> _awaitCurrentServerOperations(
    FamilyTreeData data,
    List<String> operationIds, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    var working = data;
    final requestedIds = operationIds.toSet();

    while (working.pendingSyncQueue.any(
      (item) => requestedIds.contains(item.id) && !item.requiresUserAction,
    )) {
      final remainingTime = deadline.difference(DateTime.now());
      if (remainingTime <= Duration.zero) throw TimeoutException('sync');

      final remaining = <PendingSyncItem>[];
      for (final item in working.pendingSyncQueue) {
        if (!requestedIds.contains(item.id) || item.serverOperationId.isEmpty) {
          remaining.add(item);
          continue;
        }
        final server = await _serverOperationService!
            .getOperation(item.serverOperationId)
            .timeout(remainingTime);
        if (server.status == ServerOperationStatus.completed) continue;
        final terminalFailure =
            server.status == ServerOperationStatus.rejected ||
            server.status == ServerOperationStatus.conflict ||
            server.status == ServerOperationStatus.failed;
        remaining.add(
          item.copyWith(
            status: terminalFailure
                ? 'needsResolution'
                : server.status == ServerOperationStatus.processing
                ? 'serverProcessing'
                : server.status.name,
            submissionStatus: terminalFailure
                ? 'needsResolution'
                : server.status.name,
            serverStatus: server.status.name,
            lastServerCheckAt: _now().toIso8601String(),
            lastErrorCode: server.lastErrorCode ?? '',
            lastError: server.lastErrorMessage ?? '',
            requiresUserAction: terminalFailure,
            resultVersion: server.resultVersion,
          ),
        );
      }
      working = working.copyWith(
        pendingSyncQueue: remaining,
        syncSettings: working.syncSettings.copyWith(
          syncStatus: remaining.any((item) => requestedIds.contains(item.id))
              ? 'pending'
              : 'synced',
        ),
        appSettings: working.appSettings.copyWith(
          storageSettings: working.appSettings.storageSettings.copyWith(
            syncStatus: remaining.any((item) => requestedIds.contains(item.id))
                ? 'pending'
                : 'synced',
          ),
        ),
      );
      if (remaining.any(
        (item) => requestedIds.contains(item.id) && !item.requiresUserAction,
      )) {
        final delay = deadline.difference(DateTime.now());
        if (delay <= Duration.zero) throw TimeoutException('sync');
        await Future<void>.delayed(
          delay < const Duration(milliseconds: 150)
              ? delay
              : const Duration(milliseconds: 150),
        );
      }
    }
    return working;
  }

  MemberSaveResult resultForOperationIds(
    FamilyTreeData data,
    Iterable<String> operationIds,
  ) {
    final ids = operationIds.toSet();
    final requestedIds = ids.toList(growable: false);
    final remaining = data.pendingSyncQueue
        .where((item) => ids.contains(item.id))
        .toList(growable: false);
    if (remaining.isEmpty) {
      return MemberSaveResult(
        localSaved: true,
        remoteStatus: RemoteSaveStatus.confirmed,
        operationIds: requestedIds,
      );
    }
    final codes = remaining
        .map((item) => item.lastErrorCode.trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false);
    final errors = remaining
        .map((item) => item.lastError.trim())
        .where((message) => message.isNotEmpty)
        .join('\n');
    final status =
        codes.any(
          (code) => code == 'permission-denied' || code == 'unauthenticated',
        )
        ? RemoteSaveStatus.permissionRequired
        : codes.any(
            (code) => code == 'deadline-exceeded' || code == 'local-timeout',
          )
        ? RemoteSaveStatus.timedOut
        : codes.isEmpty ||
              codes.any(
                (code) =>
                    code == 'unavailable' ||
                    code == 'network' ||
                    code == 'aborted' ||
                    code == 'resource-exhausted' ||
                    code == 'sync-error',
              )
        ? RemoteSaveStatus.unavailable
        : RemoteSaveStatus.failed;
    return MemberSaveResult(
      localSaved: true,
      remoteStatus: status,
      operationIds: requestedIds,
      firebaseCode: codes.isEmpty ? null : codes.first,
      lastError: errors,
    );
  }

  Future<FamilyTreeData> _syncPendingQueue(
    FamilyTreeData data, {
    required bool force,
  }) async {
    final storage = data.appSettings.storageSettings;
    if (!storage.remoteDatabaseEnabled ||
        !storage.autoSyncOnReconnect ||
        data.pendingSyncQueue.isEmpty) {
      return data;
    }
    final online = await _connectivity.isOnline;
    if (!online) return _markStatus(data, 'offline');

    if (_serverOperationQueueEnabled && _serverOperationService != null) {
      return _syncServerOperations(data, force: force);
    }

    var working = _markStatus(data, 'syncing');
    await _logSyncStart(working, working.pendingSyncQueue.length);
    final remaining = <PendingSyncItem>[];
    final audit = [...working.auditLog];
    var hadError = false;
    for (final item in working.pendingSyncQueue) {
      if (item.status == 'synced' ||
          item.status == 'completed' ||
          item.status == 'resolved' ||
          item.status == 'discarded' ||
          (!force &&
              (item.status == 'needsResolution' || item.requiresUserAction))) {
        remaining.add(item);
        continue;
      }
      if (!force && !_isDue(item)) {
        remaining.add(item);
        continue;
      }
      if (_hasUnresolvedDependency(item, working.pendingSyncQueue)) {
        remaining.add(item);
        continue;
      }
      _logOperation(item, working.mainFamilyCode);
      try {
        debugPrint('SYNC QUEUE SEND START operationId=${item.id}');
        await _send(item, working);
        debugPrint('SYNC QUEUE SEND SUCCESS operationId=${item.id}');
        audit.add(_log('sync_queue_item_sent', item.entityId, item.entityType));
      } on FirebaseException catch (error, stackTrace) {
        final lastError = _logFirebaseFailure(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
        );
        await _reportIncident(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
          sourceFunction: 'syncPendingQueue',
        );
        hadError = true;
        final failedItem = _withFailureDiagnostic(
          item,
          working.mainFamilyCode,
          lastError,
          error,
          stackTrace,
          sourceFunction: 'syncPendingQueue',
          retryCount: item.retryCount + 1,
        );
        remaining.add(failedItem);
        if (_shouldWriteFailureAudit(item, failedItem)) {
          audit.add(
            _log('sync_queue_item_failed', item.entityId, item.entityType),
          );
        }
      } catch (error, stackTrace) {
        final lastError = _logGenericFailure(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
        );
        await _reportIncident(
          item,
          working.mainFamilyCode,
          error,
          stackTrace,
          sourceFunction: 'syncPendingQueue',
        );
        hadError = true;
        final failedItem = _withFailureDiagnostic(
          item,
          working.mainFamilyCode,
          lastError,
          error,
          stackTrace,
          sourceFunction: 'syncPendingQueue',
          retryCount: item.retryCount + 1,
        );
        remaining.add(failedItem);
        if (_shouldWriteFailureAudit(item, failedItem)) {
          audit.add(
            _log('sync_queue_item_failed', item.entityId, item.entityType),
          );
        }
      }
    }

    final now = _now().toIso8601String();
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

  Future<FamilyTreeData> _submitOperations(
    FamilyTreeData data,
    List<PendingSyncItem> operations,
  ) async {
    if (!await _connectivity.isOnline) {
      return _enqueueAll(
        data,
        operations.map(_withStableServerIdentity).toList(),
        status: 'offline',
        operationStatus: 'pendingSubmission',
      );
    }
    final updated = <PendingSyncItem>[];
    for (final original in operations) {
      var item = _withStableServerIdentity(original);
      if (item.serverOperationId.isNotEmpty) {
        updated.add(item);
        continue;
      }
      if (item.retryCount >= maxLocalAttempts) {
        updated.add(
          item.copyWith(
            status: 'failed',
            submissionStatus: 'failed',
            requiresUserAction: true,
            lastErrorCode: 'max-attempts-exceeded',
          ),
        );
        continue;
      }
      try {
        final request = _serverRequest(item, data);
        final submission = await _serverOperationService!.submitOperation(
          localOperationId: item.localOperationId,
          idempotencyKey: item.idempotencyKey,
          familyId: data.mainFamilyCode,
          type: request.type,
          resourceId: item.entityId,
          baseVersion: request.baseVersion,
          payload: request.payload,
        );
        final now = _now().toIso8601String();
        updated.add(
          item.copyWith(
            status: 'submittedToServer',
            submissionStatus: 'submittedToServer',
            serverOperationId: submission.operationId,
            serverStatus: submission.status.name,
            submittedAt: now,
            lastServerCheckAt: now,
            lastError: '',
            lastErrorCode: '',
          ),
        );
      } on ServerOperationException catch (error) {
        final definitive = !error.isRetryable;
        updated.add(
          item.copyWith(
            retryCount: item.retryCount + 1,
            status: definitive ? 'needsResolution' : 'retryScheduled',
            submissionStatus: definitive
                ? 'needsResolution'
                : 'pendingSubmission',
            requiresUserAction: definitive,
            lastErrorCode: error.code,
            lastError: error.message,
            nextAttemptAt: definitive
                ? ''
                : _now()
                      .add(_retryDelay(item.retryCount + 1))
                      .toIso8601String(),
          ),
        );
      }
    }
    return _enqueueAll(
      data,
      updated,
      status: 'pending',
      operationStatus: 'pendingSubmission',
    );
  }

  Future<FamilyTreeData> _syncServerOperations(
    FamilyTreeData data, {
    required bool force,
  }) async {
    final remaining = <PendingSyncItem>[];
    for (final original in data.pendingSyncQueue) {
      final item = _withStableServerIdentity(original);
      if (item.serverOperationId.isEmpty) {
        if (item.requiresUserAction || item.status == 'needsResolution') {
          remaining.add(item);
          continue;
        }
        final submitted = await _submitOperations(
          data.copyWith(pendingSyncQueue: remaining),
          [item],
        );
        remaining
          ..clear()
          ..addAll(submitted.pendingSyncQueue);
        continue;
      }
      try {
        final server = await _serverOperationService!.getOperation(
          item.serverOperationId,
        );
        if (server.status == ServerOperationStatus.completed) continue;
        final requiresAction =
            server.status == ServerOperationStatus.conflict ||
            server.status == ServerOperationStatus.rejected ||
            server.status == ServerOperationStatus.failed;
        remaining.add(
          item.copyWith(
            status: server.status == ServerOperationStatus.processing
                ? 'serverProcessing'
                : server.status.name,
            submissionStatus: server.status == ServerOperationStatus.processing
                ? 'serverProcessing'
                : server.status.name,
            serverStatus: server.status.name,
            lastServerCheckAt: _now().toIso8601String(),
            lastErrorCode: server.lastErrorCode ?? '',
            lastError: server.lastErrorMessage ?? '',
            requiresUserAction: requiresAction,
            baseVersion: server.baseVersion,
            resultVersion: server.resultVersion,
            conflictedAt: server.status == ServerOperationStatus.conflict
                ? (server.completedAt ?? server.updatedAt ?? _now())
                      .toIso8601String()
                : item.conflictedAt,
          ),
        );
      } on ServerOperationException catch (error) {
        remaining.add(
          item.copyWith(
            lastServerCheckAt: _now().toIso8601String(),
            lastErrorCode: error.code,
            lastError: error.message,
            requiresUserAction: !error.isRetryable,
          ),
        );
      }
    }
    final status = remaining.isEmpty ? 'synced' : 'pending';
    return data.copyWith(
      pendingSyncQueue: remaining,
      syncSettings: data.syncSettings.copyWith(syncStatus: status),
      appSettings: data.appSettings.copyWith(
        storageSettings: data.appSettings.storageSettings.copyWith(
          syncStatus: status,
        ),
      ),
    );
  }

  PendingSyncItem _withStableServerIdentity(PendingSyncItem item) {
    final localId = item.localOperationId.isEmpty
        ? item.id
        : item.localOperationId;
    return item.copyWith(
      localOperationId: localId,
      idempotencyKey: item.idempotencyKey.isEmpty
          ? 'ayivon-local:$localId'
          : item.idempotencyKey,
      submissionStatus: item.submissionStatus.isEmpty
          ? 'pendingSubmission'
          : item.submissionStatus,
    );
  }

  ({ServerOperationType type, int baseVersion, Map<String, dynamic> payload})
  _serverRequest(PendingSyncItem item, FamilyTreeData data) {
    if (item.entityType == 'person') {
      final person = item.payload.isEmpty
          ? data.people.firstWhere((person) => person.id == item.entityId)
          : Person.fromJson(item.payload);
      final mapper = const FirestoreDocumentMapper();
      final public = mapper.toMemberPublic(
        person,
        familyId: data.mainFamilyCode,
      )..remove('updatedAt');
      final private =
          mapper.toMemberPrivate(person, familyId: data.mainFamilyCode)
            ..remove('updatedAt')
            ..remove('updatedBy')
            ..remove('version');
      final type = item.action == 'delete'
          ? ServerOperationType.memberSoftDelete
          : item.action == 'create' || item.action == 'restore'
          ? ServerOperationType.memberCreate
          : ServerOperationType.memberUpdate;
      return (
        type: type,
        baseVersion: type == ServerOperationType.memberCreate
            ? 0
            : max(0, person.version - 1),
        payload: type == ServerOperationType.memberSoftDelete
            ? const <String, dynamic>{}
            : {'public': public, 'private': private},
      );
    }
    final isLink = item.entityType == 'familyLink';
    final prefix = isLink ? 'familyTreeLink' : 'relationship';
    final suffix = item.action == 'delete'
        ? 'delete'
        : item.action == 'create' || item.action == 'restore'
        ? 'create'
        : 'update';
    return (
      type: ServerOperationType.parse('$prefix.$suffix'),
      baseVersion: suffix == 'create'
          ? 0
          : max(0, ((item.payload['version'] as num?)?.toInt() ?? 1) - 1),
      payload: Map<String, dynamic>.from(item.payload)
        ..remove('updatedAt')
        ..remove('createdAt')
        ..remove('updatedBy')
        ..remove('version'),
    );
  }

  PendingSyncItem personOperation({
    required Person person,
    required String action,
    required String updatedBy,
  }) {
    final now = _now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${_now().microsecondsSinceEpoch}',
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
    final now = _now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${_now().microsecondsSinceEpoch}',
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
    final now = _now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${_now().microsecondsSinceEpoch}',
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
    final now = _now().toIso8601String();
    return PendingSyncItem(
      id: 'sync${_now().microsecondsSinceEpoch}',
      entityType: 'familyLink',
      entityId: link.id,
      action: action,
      payload: link.toJson(),
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }

  Future<void> _send(PendingSyncItem item, FamilyTreeData data) async {
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
      debugPrint('SYNC REMOTE deletePerson personId=${item.entityId}');
      await _remoteRepository.deletePerson(item.entityId);
      return;
    }
    final person = item.payload.isEmpty
        ? data.people.firstWhere(
            (person) => person.id == item.entityId,
            orElse: () => throw StateError(
              'Membre local introuvable pour la synchronisation: '
              '${item.entityId}',
            ),
          )
        : Person.fromJson(item.payload);
    if (item.action == 'create' || item.action == 'restore') {
      debugPrint('SYNC REMOTE createPerson personId=${person.id}');
      await _remoteRepository.createPerson(person);
    } else {
      debugPrint('SYNC REMOTE updatePerson personId=${person.id}');
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
        ..._removeMatchingOperations(queue, [operation]),
        operation.copyWith(
          status: operation.status == 'pending'
              ? operationStatus
              : operation.status,
        ),
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

  List<PendingSyncItem> _removeMatchingOperations(
    List<PendingSyncItem> queue,
    List<PendingSyncItem> operations,
  ) {
    if (operations.isEmpty || queue.isEmpty) return queue;
    return queue
        .where(
          (item) => !operations.any((operation) {
            return item.entityType == operation.entityType &&
                item.entityId == operation.entityId &&
                item.action == operation.action;
          }),
        )
        .toList();
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
      id: 'log${_now().microsecondsSinceEpoch}',
      date: _now().toIso8601String(),
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
    debugPrint('AUTH UID: ${_maskIdentifier(user?.uid ?? '')}');
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

  String _maskIdentifier(String value) {
    if (value.length <= 6) return value.isEmpty ? '<none>' : '***';
    return '${value.substring(0, 3)}…${value.substring(value.length - 3)}';
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
    debugPrint('FIREBASE PLUGIN: ${error.plugin}');
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

  PendingSyncItem _withFailureDiagnostic(
    PendingSyncItem item,
    String familyId,
    String lastError,
    Object error,
    StackTrace stackTrace, {
    required String sourceFunction,
    String? status,
    int? retryCount,
  }) {
    final incident = _failureDiagnostic(
      item,
      familyId,
      lastError,
      error,
      stackTrace,
      sourceFunction: sourceFunction,
    );
    final nextRetryCount = retryCount ?? item.retryCount;
    final errorCode = _errorCode(error, lastError);
    final requiresResolution = _requiresManualResolution(
      item,
      lastError,
      error,
      nextRetryCount,
    );
    final nextStatus =
        status ??
        (requiresResolution
            ? 'needsResolution'
            : _isRetryableError(errorCode, lastError)
            ? 'retryScheduled'
            : 'failed');
    final retryAt = nextStatus == 'retryScheduled'
        ? _nextAttemptAt(nextRetryCount).toIso8601String()
        : '';
    return item.copyWith(
      status: nextStatus,
      retryCount: nextRetryCount,
      lastError: lastError,
      lastErrorCode: errorCode,
      lastAttemptAt: _now().toIso8601String(),
      nextAttemptAt: retryAt,
      requiresUserAction: nextStatus == 'needsResolution',
      errorType: incident.errorType,
      stackTrace: incident.stackTrace,
      sourceFile: incident.sourceFile,
      sourceFunction: incident.sourceFunction,
      sourceLine: incident.sourceLine,
      sourceColumn: incident.sourceColumn,
      routeName: incident.routeName,
      appVersion: incident.appVersion,
      platform: incident.platform,
      locationPrecision: incident.locationPrecision,
    );
  }

  bool _requiresManualResolution(
    PendingSyncItem item,
    String lastError,
    Object error,
    int retryCount,
  ) {
    final code = _errorCode(error, lastError);
    final message = lastError.toLowerCase();
    if (code == 'permission-denied' || code == 'unauthenticated') {
      return true;
    }
    if (code == 'invalid-argument' || code == 'failed-precondition') {
      return true;
    }
    return message.contains('familyid') ||
        message.contains('role insuffisant') ||
        message.contains('champ obligatoire') ||
        message.contains('document invalide') ||
        message.contains('identifiant incoherent') ||
        message.contains('identifiant incohérent');
  }

  PendingSyncItem _scheduleRetry(PendingSyncItem item) {
    final retryCount = item.retryCount == 0 ? 1 : item.retryCount;
    return item.copyWith(
      status: 'retryScheduled',
      retryCount: retryCount,
      lastAttemptAt: item.lastAttemptAt,
      nextAttemptAt: item.nextAttemptAt.isEmpty
          ? _nextAttemptAt(retryCount).toIso8601String()
          : item.nextAttemptAt,
      requiresUserAction: false,
    );
  }

  bool _isDue(PendingSyncItem item) {
    if (item.nextAttemptAt.isEmpty) return true;
    final dueAt = DateTime.tryParse(item.nextAttemptAt);
    if (dueAt == null) return true;
    return !dueAt.isAfter(_now());
  }

  bool _hasUnresolvedDependency(
    PendingSyncItem item,
    List<PendingSyncItem> queue,
  ) {
    if (item.dependsOnOperationIds.isEmpty) return false;
    final openIds = queue
        .where((operation) {
          return operation.status != 'completed' &&
              operation.status != 'synced' &&
              operation.status != 'resolved' &&
              operation.status != 'discarded';
        })
        .map((operation) => operation.id)
        .toSet();
    return item.dependsOnOperationIds.any(openIds.contains);
  }

  bool _shouldWriteFailureAudit(PendingSyncItem before, PendingSyncItem after) {
    return before.status != after.status ||
        before.lastErrorCode != after.lastErrorCode ||
        after.status == 'needsResolution';
  }

  bool _isRetryableError(String code, String lastError) {
    final message = lastError.toLowerCase();
    if (code == 'permission-denied' || code == 'unauthenticated') {
      return false;
    }
    const retryableCodes = {
      'aborted',
      'deadline-exceeded',
      'internal',
      'network',
      'resource-exhausted',
      'sync-error',
      'unavailable',
      'unknown',
    };
    return retryableCodes.contains(code) ||
        message.contains('timeout') ||
        message.contains('tempor') ||
        message.contains('network') ||
        message.contains('connexion') ||
        message.contains('unavailable') ||
        message.contains('converted future');
  }

  String _errorCode(Object error, String lastError) {
    if (error is FirebaseException && error.code.isNotEmpty) {
      return error.code;
    }
    final lower = lastError.toLowerCase();
    const knownCodes = [
      'permission-denied',
      'deadline-exceeded',
      'resource-exhausted',
      'failed-precondition',
      'invalid-argument',
      'unauthenticated',
      'unavailable',
      'aborted',
      'not-found',
    ];
    for (final code in knownCodes) {
      if (lower.contains(code)) return code;
    }
    if (lower.contains('network') || lower.contains('connexion')) {
      return 'network';
    }
    return 'sync-error';
  }

  DateTime _nextAttemptAt(int retryCount) {
    final baseDelay = _retryDelay(retryCount);
    final jitter = 0.8 + (_random.nextDouble() * 0.4);
    final seconds = max(1, (baseDelay.inSeconds * jitter).round());
    return _now().add(Duration(seconds: seconds));
  }

  Duration _retryDelay(int retryCount) {
    if (retryCount <= 1) return const Duration(seconds: 10);
    if (retryCount == 2) return const Duration(seconds: 30);
    if (retryCount == 3) return const Duration(minutes: 1);
    if (retryCount == 4) return const Duration(minutes: 5);
    if (retryCount == 5) return const Duration(minutes: 15);
    return const Duration(minutes: 30);
  }

  DateTime _now() => _nowProvider?.call() ?? DateTime.now();

  SyncIncident _failureDiagnostic(
    PendingSyncItem item,
    String familyId,
    String lastError,
    Object error,
    StackTrace stackTrace, {
    required String sourceFunction,
  }) {
    return IncidentReporter.buildIncident(
      item: item.copyWith(lastError: lastError),
      familyId: familyId,
      error: error,
      stackTrace: stackTrace,
      sourceFunction: sourceFunction,
    );
  }

  Future<void> _reportIncident(
    PendingSyncItem item,
    String familyId,
    Object error,
    StackTrace stackTrace, {
    required String sourceFunction,
  }) async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await _incidentReporter.report(
      item: item.copyWith(retryCount: item.retryCount + 1),
      familyId: familyId,
      error: error,
      stackTrace: stackTrace,
      userId: user?.uid ?? '',
      userEmail: user?.email ?? '',
      sourceFunction: sourceFunction,
    );
  }
}
