import '../../models/family_tree_data.dart';
import '../../models/person.dart';

abstract class FamilyDataRepository {
  Future<FamilyTreeData> load(String familyId);
  Future<void> save(FamilyTreeData data);
  Future<Person> savePerson(Person person);
  Future<void> deletePerson(String id);
}
