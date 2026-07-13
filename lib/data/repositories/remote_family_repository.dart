import '../../models/family_tree_data.dart';
import '../../models/person.dart';
import '../remote/family_api.dart';
import 'family_repository.dart';

class RemoteFamilyRepository implements FamilyDataRepository {
  const RemoteFamilyRepository(this._api);

  final FamilyApi _api;

  @override
  Future<FamilyTreeData> load(String familyId) => _api.pullFamilyTree(familyId);

  @override
  Future<void> save(FamilyTreeData data) async {
    for (final person in data.people) {
      await _api.savePerson(person);
    }
  }

  @override
  Future<Person> savePerson(Person person) => _api.savePerson(person);

  @override
  Future<void> deletePerson(String id) => _api.deletePerson(id);
}
