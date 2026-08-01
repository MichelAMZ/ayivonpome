import '../models/family_tree_data.dart';
import '../models/person.dart';
import 'remote_database_repository.dart';
import 'app_error_logger.dart';

/// Point d'entrée unique des écritures Firestore concernant les membres.
///
/// Le dépôt distant conserve l'implémentation des WriteBatch. Ce service
/// interdit aux contrôleurs et widgets de combiner cache local et file de
/// rejeu pour confirmer une écriture.
class MemberFirestoreService {
  const MemberFirestoreService(this._repository, {AppErrorLogger? errorLogger})
    : _errorLogger = errorLogger;

  final DatabaseFamilyRepository _repository;
  final AppErrorLogger? _errorLogger;

  Future<void> createMember(Person person) => _run(
    () => _repository.createPerson(person),
    feature: 'member_create',
    operation: 'create',
    entityId: person.id,
  );

  Future<void> updateMember(Person person) => _run(
    () => _repository.updatePerson(person),
    feature: 'member_update',
    operation: 'update',
    entityId: person.id,
  );

  Future<void> softDeleteMember(String memberId) => _run(
    () => _repository.deletePerson(memberId),
    feature: 'member_delete',
    operation: 'soft_delete',
    entityId: memberId,
  );

  Future<void> upsertMemberGraph(FamilyTreeData data) => _run(
    () => _repository.saveFamilyTree(data),
    feature: 'member_graph_update',
    operation: 'update_graph',
  );

  Future<void> _run(
    Future<void> Function() action, {
    required String feature,
    required String operation,
    String entityId = '',
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      await _errorLogger?.capture(
        error: error,
        stackTrace: stackTrace,
        feature: feature,
        operation: operation,
        entityType: 'member',
        entityId: entityId,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
