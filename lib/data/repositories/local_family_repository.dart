import '../../models/family_tree_data.dart';
import '../../models/person.dart';
import '../local/local_database.dart';
import 'family_repository.dart';

class LocalFamilyRepository implements FamilyDataRepository {
  const LocalFamilyRepository(this._database);

  final LocalDatabase _database;

  @override
  Future<FamilyTreeData> load(String familyId) async {
    return await _database.readFamilyTree() ??
        FamilyTreeData(mainFamilyCode: familyId);
  }

  @override
  Future<void> save(FamilyTreeData data) => _database.writeFamilyTree(data);

  @override
  Future<Person> savePerson(Person person) async {
    final data = await load(person.familyId);
    final people = [...data.people];
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1) {
      people.add(person);
    } else {
      people[index] = person;
    }
    await save(data.copyWith(people: people));
    return person;
  }

  @override
  Future<void> deletePerson(String id) async {
    final data = await _database.readFamilyTree();
    if (data == null) return;
    await save(
      data.copyWith(
        people: data.people.where((item) => item.id != id).toList(),
      ),
    );
  }
}
