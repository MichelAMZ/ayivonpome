import 'dart:async';

import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/sync_incident.dart';
import 'family_repository.dart';

class RemoteDatabaseFamilyRepository implements FamilyRepository {
  const RemoteDatabaseFamilyRepository({RemoteDatabaseClient? client})
    : _client = client ?? const UnconfiguredRemoteDatabaseClient();

  final RemoteDatabaseClient _client;

  @override
  Future<FamilyTreeData> loadFamilyTree() => _client.loadFamilyTree();

  Stream<FamilyTreeData> watchFamilyTree() => _client.watchFamilyTree();

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) =>
      _client.saveFamilyTree(data);

  @override
  Future<void> createPerson(Person person) => _client.createPerson(person);

  @override
  Future<void> updatePerson(Person person) => _client.updatePerson(person);

  @override
  Future<void> deletePerson(String personId) => _client.deletePerson(personId);

  @override
  Future<void> createMarriage(MarriageRelation relation) =>
      _client.createMarriage(relation);

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      _client.updateMarriage(relation);

  @override
  Future<void> deleteMarriage(String relationId) =>
      _client.deleteMarriage(relationId);

  @override
  Future<void> createFamilyLink(FamilyLink link) =>
      _client.createFamilyLink(link);

  @override
  Future<void> updateFamilyLink(FamilyLink link) =>
      _client.updateFamilyLink(link);

  @override
  Future<void> createAuditLog(AuditLog log) => _client.createAuditLog(log);

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) =>
      _client.upsertSyncIncident(incident);
}

typedef DatabaseFamilyRepository = RemoteDatabaseFamilyRepository;

abstract class RemoteDatabaseClient {
  Future<void> savePerson(Person person);
  Future<void> saveFamilyTree(FamilyTreeData data);
  Future<void> createPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<void> deletePerson(String personId);
  Future<FamilyTreeData> loadFamilyTree();
  Future<void> createMarriage(MarriageRelation relation);
  Future<void> updateMarriage(MarriageRelation relation);
  Future<void> deleteMarriage(String relationId);
  Future<void> createFamilyLink(FamilyLink link);
  Future<void> updateFamilyLink(FamilyLink link);
  Future<void> createAuditLog(AuditLog log);
  Future<void> upsertSyncIncident(SyncIncident incident);
  Stream<FamilyTreeData> watchFamilyTree();
}

class UnconfiguredRemoteDatabaseClient implements RemoteDatabaseClient {
  const UnconfiguredRemoteDatabaseClient();

  @override
  Future<void> savePerson(Person person) => _notConfigured();

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) => _notConfigured();

  @override
  Future<void> createPerson(Person person) => _notConfigured();

  @override
  Future<void> updatePerson(Person person) => _notConfigured();

  @override
  Future<void> deletePerson(String personId) => _notConfigured();

  @override
  Future<FamilyTreeData> loadFamilyTree() => _notConfigured();

  @override
  Stream<FamilyTreeData> watchFamilyTree() {
    return Stream.error(
      const RemoteDatabaseUnavailableException(
        'Remote database client is not configured yet.',
      ),
    );
  }

  @override
  Future<void> createMarriage(MarriageRelation relation) => _notConfigured();

  @override
  Future<void> updateMarriage(MarriageRelation relation) => _notConfigured();

  @override
  Future<void> deleteMarriage(String relationId) => _notConfigured();

  @override
  Future<void> createFamilyLink(FamilyLink link) => _notConfigured();

  @override
  Future<void> updateFamilyLink(FamilyLink link) => _notConfigured();

  @override
  Future<void> createAuditLog(AuditLog log) => _notConfigured();

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) => _notConfigured();

  Future<T> _notConfigured<T>() {
    throw const RemoteDatabaseUnavailableException(
      'Remote database client is not configured yet.',
    );
  }
}

class RemoteDatabaseUnavailableException implements Exception {
  const RemoteDatabaseUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
