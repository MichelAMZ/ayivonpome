import '../models/family_tree_data.dart';
import '../models/person.dart';
import 'remote_database_repository.dart';

/// Point d'entrée unique des écritures Firestore concernant les membres.
///
/// Le dépôt distant conserve l'implémentation des WriteBatch. Ce service
/// interdit aux contrôleurs et widgets de combiner cache local et file de
/// rejeu pour confirmer une écriture.
class MemberFirestoreService {
  const MemberFirestoreService(this._repository);

  final DatabaseFamilyRepository _repository;

  Future<void> createMember(Person person) => _repository.createPerson(person);

  Future<void> updateMember(Person person) => _repository.updatePerson(person);

  Future<void> softDeleteMember(String memberId) =>
      _repository.deletePerson(memberId);

  Future<void> upsertMemberGraph(FamilyTreeData data) =>
      _repository.saveFamilyTree(data);
}
