import '../../models/family_tree_data.dart';
import '../../models/person.dart';
import 'family_repository.dart';

class HybridFamilyRepository implements FamilyDataRepository {
  const HybridFamilyRepository({
    required FamilyDataRepository local,
    required FamilyDataRepository remote,
  }) : _local = local,
       _remote = remote;

  final FamilyDataRepository _local;
  final FamilyDataRepository _remote;

  @override
  Future<FamilyTreeData> load(String familyId) async {
    try {
      final remote = await _remote.load(familyId);
      await _local.save(remote);
      return remote;
    } catch (_) {
      return _local.load(familyId);
    }
  }

  @override
  Future<void> save(FamilyTreeData data) async {
    await _local.save(data);
    await _remote.save(data);
  }

  @override
  Future<Person> savePerson(Person person) async {
    await _local.savePerson(person);
    return _remote.savePerson(person);
  }

  @override
  Future<void> deletePerson(String id) async {
    await _local.deletePerson(id);
    await _remote.deletePerson(id);
  }
}
