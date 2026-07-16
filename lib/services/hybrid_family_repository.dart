import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/sync_incident.dart';
import 'family_repository.dart';

class HybridFamilyRepository implements FamilyRepository {
  const HybridFamilyRepository({
    required FamilyRepository localRepository,
    required FamilyRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository;

  final FamilyRepository _localRepository;
  final FamilyRepository _remoteRepository;

  @override
  Future<FamilyTreeData> loadFamilyTree() => _localRepository.loadFamilyTree();

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) async {
    await _localRepository.saveFamilyTree(data);
    await _remoteRepository.saveFamilyTree(data);
  }

  @override
  Future<void> createPerson(Person person) =>
      _writeBoth((repository) => repository.createPerson(person));

  @override
  Future<void> updatePerson(Person person) =>
      _writeBoth((repository) => repository.updatePerson(person));

  @override
  Future<void> deletePerson(String personId) =>
      _writeBoth((repository) => repository.deletePerson(personId));

  @override
  Future<void> createMarriage(MarriageRelation relation) =>
      _writeBoth((repository) => repository.createMarriage(relation));

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      _writeBoth((repository) => repository.updateMarriage(relation));

  @override
  Future<void> deleteMarriage(String relationId) =>
      _writeBoth((repository) => repository.deleteMarriage(relationId));

  @override
  Future<void> createFamilyLink(FamilyLink link) =>
      _writeBoth((repository) => repository.createFamilyLink(link));

  @override
  Future<void> updateFamilyLink(FamilyLink link) =>
      _writeBoth((repository) => repository.updateFamilyLink(link));

  @override
  Future<void> createAuditLog(AuditLog log) =>
      _writeBoth((repository) => repository.createAuditLog(log));

  @override
  Future<int> deleteActivityLogs({
    required String familyId,
    DateTime? olderThan,
    required String actorUid,
    required String actorRole,
    required String retentionLabel,
  }) async {
    await _remoteRepository.deleteActivityLogs(
      familyId: familyId,
      olderThan: olderThan,
      actorUid: actorUid,
      actorRole: actorRole,
      retentionLabel: retentionLabel,
    );
    return _localRepository.deleteActivityLogs(
      familyId: familyId,
      olderThan: olderThan,
      actorUid: actorUid,
      actorRole: actorRole,
      retentionLabel: retentionLabel,
    );
  }

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) =>
      _remoteRepository.upsertSyncIncident(incident);

  Future<void> _writeBoth(
    Future<void> Function(FamilyRepository repository) write,
  ) async {
    await write(_localRepository);
    await write(_remoteRepository);
  }
}
