import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_link.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/models/sync_incident.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/services/connectivity_service.dart';
import 'package:ayivonpome/services/family_repository.dart';
import 'package:ayivonpome/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      expect(pending.single.status, 'failed');
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
  _FakeFamilyRepository({this.shouldFailUpdates = false});

  final bool shouldFailUpdates;
  final updatedPeople = <Person>[];

  @override
  Future<void> updatePerson(Person person) async {
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
  Future<void> createPerson(Person person) => throw UnimplementedError();

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
  Future<void> upsertSyncIncident(SyncIncident incident) async {}
}
