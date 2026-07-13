import '../../core/network/api_client.dart';
import '../../models/family_tree_data.dart';
import '../../models/person.dart';

class FamilyApi {
  const FamilyApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> families() async {
    final response = await _client.get('/families');
    return List<Map<String, dynamic>>.from(
      response['data'] as List? ?? const [],
    );
  }

  Future<List<Person>> people(String familyId) async {
    final response = await _client.get(
      '/people',
      query: {'familyId': familyId},
    );
    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _personFromApi(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Person> savePerson(Person person) async {
    final response = await _client.post('/people', body: person.toJson());
    return _personFromApi(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> deletePerson(String id) async {
    await _client.delete('/people/$id');
  }

  Future<FamilyTreeData> pullFamilyTree(String familyId) async {
    final people = await this.people(familyId);
    return FamilyTreeData(people: people, mainFamilyCode: familyId);
  }

  Person _personFromApi(Map<String, dynamic> json) {
    return Person.fromJson({
      'id': json['id'],
      'familyId': json['family_id'],
      'originFamilyId': json['origin_family_id'],
      'firstName': json['first_name'],
      'lastName': json['last_name'],
      'birthLastName': json['birth_last_name'],
      'gender': json['gender'],
      'birthDate': json['birth_date'] ?? '',
      'birthPlace': json['birth_place'] ?? '',
      'deathDate': json['death_date'] ?? '',
      'deathPlace': json['death_place'] ?? '',
      'burialPlace': json['burial_place'] ?? '',
      'currentAddress': json['current_address'] ?? '',
      'currentCity': json['current_city'] ?? '',
      'currentRegion': json['current_region'] ?? '',
      'currentCountry': json['current_country'] ?? '',
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'email': json['email'] ?? '',
      'phoneNumber': json['phone_number'] ?? '',
      'whatsappNumber': json['whatsapp_number'] ?? '',
      'photo': json['photo_url'] ?? '',
      'notes': json['notes'] ?? '',
      'linkedTreeEnabled':
          json['linked_tree_enabled'] == 1 ||
          json['linked_tree_enabled'] == true,
      'version': json['version'] ?? 1,
    });
  }
}
