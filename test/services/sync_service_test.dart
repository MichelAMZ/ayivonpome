import 'dart:math';
import 'dart:async';

import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_link.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/member_save_result.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/models/sync_incident.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/services/connectivity_service.dart';
import 'package:ayivonpome/services/family_repository.dart';
import 'package:ayivonpome/services/sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'current operation is confirmed independently from older queue items',
    () async {
      final repository = _FakeFamilyRepository();
      final service = SyncService(
        connectivity: const _OnlineConnectivityService(),
        remoteRepository: repository,
      );
      const person = Person(id: 'person-123', firstName: 'Kossi');
      final current = service.personOperation(
        person: person,
        action: 'update',
        updatedBy: 'test',
      );
      const unrelated = PendingSyncItem(
        id: 'older-operation',
        entityType: 'person',
        entityId: 'another-person',
        action: 'update',
        status: 'needsResolution',
      );

      final attempt = await service.attemptCurrentOperations(
        _tree(people: const [person], pendingSyncQueue: [unrelated, current]),
        operations: [current],
      );

      expect(attempt.result.isFirestoreConfirmed, isTrue);
      expect(attempt.result.operationIds, [current.id]);
      expect(attempt.data.pendingSyncQueue.single.id, unrelated.id);
    },
  );

  test('permission-denied is returned as permissionRequired', () async {
    final repository = _FakeFamilyRepository(shouldDenyCreates: true);
    final service = SyncService(
      connectivity: const _OnlineConnectivityService(),
      remoteRepository: repository,
    );
    const person = Person(id: 'person-123', firstName: 'Kossi');
    final operation = service.personOperation(
      person: person,
      action: 'create',
      updatedBy: 'test',
    );

    final attempt = await service.attemptCurrentOperations(
      _tree(people: const [person], pendingSyncQueue: [operation]),
      operations: [operation],
    );

    expect(attempt.result.remoteStatus, RemoteSaveStatus.permissionRequired);
    expect(attempt.result.firebaseCode, 'permission-denied');
    expect(attempt.data.pendingSyncQueue, isNotEmpty);
  });

  test('a timed out current operation remains pending', () async {
    final repository = _FakeFamilyRepository(hangUpdates: true);
    final service = SyncService(
      connectivity: const _OnlineConnectivityService(),
      remoteRepository: repository,
    );
    const person = Person(id: 'person-123', firstName: 'Kossi');
    final operation = service.personOperation(
      person: person,
      action: 'update',
      updatedBy: 'test',
    );
    final data = _tree(people: const [person], pendingSyncQueue: [operation]);

    final attempt = await service.attemptCurrentOperations(
      data,
      operations: [operation],
      timeout: const Duration(milliseconds: 10),
    );

    expect(attempt.result.remoteStatus, RemoteSaveStatus.timedOut);
    expect(attempt.data.pendingSyncQueue.single.id, operation.id);
  });

  test(
    'replaces pending update for same person after repeated failure',
    () async {
      final repository = _FakeFamilyRepository(shouldFailUpdates: true);
      final service = SyncService(
        connectivity: const _OnlineConnectivityService(),
        remoteRepository: repository,
      );
      const original = Person(id: 'person-123', firstName: 'Kossi');
      const latest = Person(id: 'person-123', firstName: 'Kossi modifie');
      final firstOperation = service.personOperation(
        person: original,
        action: 'update',
        updatedBy: 'test',
      );
      final secondOperation = service.personOperation(
        person: latest,
        action: 'update',
        updatedBy: 'test',
      );

      final firstResult = await service.enqueueOrSyncMany(
        _tree(people: const [original]),
        operations: [firstOperation],
      );
      final secondResult = await service.enqueueOrSyncMany(
        firstResult.copyWith(people: const [latest]),
        operations: [secondOperation],
      );

      final pending = secondResult.pendingSyncQueue
          .where(
            (item) =>
                item.entityType == 'person' &&
                item.entityId == 'person-123' &&
                item.action == 'update',
          )
          .toList();
      expect(pending, hasLength(1));
      expect(pending.single.id, secondOperation.id);
      expect(pending.single.payload['firstName'], 'Kossi modifie');
      expect(pending.single.status, 'retryScheduled');
      expect(pending.single.nextAttemptAt, isNotEmpty);
      expect(pending.single.errorType, 'StateError');
      expect(pending.single.stackTrace, isNotEmpty);
      expect(pending.single.sourceFile, contains('sync_service_test.dart'));
      expect(pending.single.sourceLine, isNotNull);
    },
  );

  test(
    'removes previous pending update after successful remote save',
    () async {
      final repository = _FakeFamilyRepository();
      final service = SyncService(
        connectivity: const _OnlineConnectivityService(),
        remoteRepository: repository,
      );
      const person = Person(id: 'person-123', firstName: 'Kossi final');
      final oldOperation = PendingSyncItem(
        id: 'old-sync',
        entityType: 'person',
        entityId: 'person-123',
        action: 'update',
        payload: const {'id': 'person-123', 'firstName': 'Kossi old'},
        updatedAt: DateTime(2026, 7, 13).toIso8601String(),
        status: 'failed',
        lastError: 'permission-denied',
      );
      final newOperation = service.personOperation(
        person: person,
        action: 'update',
        updatedBy: 'test',
      );

      final result = await service.enqueueOrSyncMany(
        _tree(people: const [person], pendingSyncQueue: [oldOperation]),
        operations: [newOperation],
      );

      expect(
        result.pendingSyncQueue.where(
          (item) =>
              item.entityType == 'person' &&
              item.entityId == 'person-123' &&
              item.action == 'update',
        ),
        isEmpty,
      );
      expect(repository.updatedPeople.single.firstName, 'Kossi final');
    },
  );

  test(
    'marks permission-denied create as needsResolution immediately',
    () async {
      final repository = _FakeFamilyRepository(shouldDenyCreates: true);
      final service = SyncService(
        connectivity: const _OnlineConnectivityService(),
        remoteRepository: repository,
      );
      const person = Person(id: 'p1784208484332000', firstName: 'Nouveau');
      final operation = service
          .personOperation(person: person, action: 'create', updatedBy: 'test')
          .copyWith(status: 'pending');

      final result = await service.syncPendingQueue(
        _tree(people: const [person], pendingSyncQueue: [operation]),
      );

      expect(result.pendingSyncQueue, hasLength(1));
      expect(result.pendingSyncQueue.single.status, 'needsResolution');
      expect(result.pendingSyncQueue.single.retryCount, 1);
      expect(result.pendingSyncQueue.single.requiresUserAction, isTrue);
      expect(
        result.pendingSyncQueue.single.lastError,
        contains('permission-denied'),
      );
    },
  );

  test('does not retry a scheduled operation before nextAttemptAt', () async {
    final repository = _FakeFamilyRepository();
    final now = DateTime(2026, 7, 16, 10);
    final service = SyncService(
      connectivity: const _OnlineConnectivityService(),
      remoteRepository: repository,
      nowProvider: () => now,
      random: Random(0),
    );
    const person = Person(id: 'person-123', firstName: 'Kossi');
    final operation = service
        .personOperation(person: person, action: 'create', updatedBy: 'test')
        .copyWith(
          status: 'retryScheduled',
          retryCount: 1,
          nextAttemptAt: now.add(const Duration(minutes: 1)).toIso8601String(),
        );

    final result = await service.syncPendingQueue(
      _tree(people: const [person], pendingSyncQueue: [operation]),
    );

    expect(result.pendingSyncQueue, hasLength(1));
    expect(result.pendingSyncQueue.single.id, operation.id);
    expect(repository.createdPeople, isEmpty);
  });

  test('manual retry ignores retry delay for retryable operations', () async {
    final repository = _FakeFamilyRepository();
    final now = DateTime(2026, 7, 16, 10);
    final service = SyncService(
      connectivity: const _OnlineConnectivityService(),
      remoteRepository: repository,
      nowProvider: () => now,
      random: Random(0),
    );
    const person = Person(id: 'person-123', firstName: 'Kossi');
    final operation = service
        .personOperation(person: person, action: 'create', updatedBy: 'test')
        .copyWith(
          status: 'retryScheduled',
          retryCount: 1,
          nextAttemptAt: now.add(const Duration(minutes: 1)).toIso8601String(),
        );

    final result = await service.syncPendingQueue(
      _tree(people: const [person], pendingSyncQueue: [operation]),
      force: true,
    );

    expect(result.pendingSyncQueue, isEmpty);
    expect(repository.createdPeople.single.id, 'person-123');
  });

  test(
    'manual retry can resume an operation waiting for authorization',
    () async {
      final repository = _FakeFamilyRepository();
      final service = SyncService(
        connectivity: const _OnlineConnectivityService(),
        remoteRepository: repository,
      );
      const person = Person(id: 'person-123', firstName: 'Kossi');
      final operation = service
          .personOperation(person: person, action: 'create', updatedBy: 'test')
          .copyWith(status: 'needsResolution', requiresUserAction: true);

      final result = await service.syncPendingQueue(
        _tree(people: const [person], pendingSyncQueue: [operation]),
        force: true,
      );

      expect(result.pendingSyncQueue, isEmpty);
      expect(repository.createdPeople.single.id, 'person-123');
    },
  );
}

FamilyTreeData _tree({
  required List<Person> people,
  List<PendingSyncItem> pendingSyncQueue = const [],
}) {
  return FamilyTreeData(
    mainFamilyCode: 'ayivon',
    people: people,
    pendingSyncQueue: pendingSyncQueue,
  );
}

class _OnlineConnectivityService extends ConnectivityService {
  const _OnlineConnectivityService();

  @override
  Future<bool> get isOnline async => true;
}

class _FakeFamilyRepository implements FamilyRepository {
  _FakeFamilyRepository({
    this.shouldFailUpdates = false,
    this.shouldDenyCreates = false,
    this.hangUpdates = false,
  });

  final bool shouldFailUpdates;
  final bool shouldDenyCreates;
  final bool hangUpdates;
  final createdPeople = <Person>[];
  final updatedPeople = <Person>[];

  @override
  Future<void> updatePerson(Person person) async {
    if (hangUpdates) await Completer<void>().future;
    if (shouldFailUpdates) {
      throw StateError('remote update failed');
    }
    updatedPeople.add(person);
  }

  @override
  Future<FamilyTreeData> loadFamilyTree() => throw UnimplementedError();

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) =>
      throw UnimplementedError();

  @override
  Future<void> createPerson(Person person) async {
    if (shouldDenyCreates) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
    }
    createdPeople.add(person);
  }

  @override
  Future<void> deletePerson(String personId) => throw UnimplementedError();

  @override
  Future<void> createMarriage(MarriageRelation relation) =>
      throw UnimplementedError();

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      throw UnimplementedError();

  @override
  Future<void> deleteMarriage(String relationId) => throw UnimplementedError();

  @override
  Future<void> createFamilyLink(FamilyLink link) => throw UnimplementedError();

  @override
  Future<void> updateFamilyLink(FamilyLink link) => throw UnimplementedError();

  @override
  Future<void> createAuditLog(AuditLog log) => throw UnimplementedError();

  @override
  Future<int> deleteActivityLogs({
    required String familyId,
    DateTime? olderThan,
    required String actorUid,
    required String actorRole,
    required String retentionLabel,
  }) => throw UnimplementedError();

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) async {}
}
