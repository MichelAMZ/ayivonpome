import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/sync_incident.dart';

abstract class FamilyRepository {
  Future<FamilyTreeData> loadFamilyTree();
  Future<void> saveFamilyTree(FamilyTreeData data);

  Future<void> createPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<void> deletePerson(String personId);

  Future<void> createMarriage(MarriageRelation relation);
  Future<void> updateMarriage(MarriageRelation relation);
  Future<void> deleteMarriage(String relationId);

  Future<void> createFamilyLink(FamilyLink link);
  Future<void> updateFamilyLink(FamilyLink link);

  Future<void> createAuditLog(AuditLog log);
  Future<void> upsertSyncIncident(SyncIncident incident);
}
