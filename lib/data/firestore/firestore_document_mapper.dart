import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/person.dart';

class FirestoreDocumentMapper {
  const FirestoreDocumentMapper();

  static const memberSchemaVersion = 2;

  Map<String, dynamic> toMemberPublic(
    Person person, {
    required String familyId,
  }) {
    final birthYear = _yearFromDate(person.birthDate);
    return {
      'id': person.id,
      'familyId': familyId,
      'firstName': person.firstName,
      'lastName': person.lastName,
      'gender': person.gender,
      'fatherId': person.fatherId,
      'motherId': person.motherId,
      'spouseIds': person.spouseIds,
      'childrenIds': person.childrenIds,
      'parents': person.parents,
      'spouses': person.spouses,
      'children': person.children,
      'birthYear': ?birthYear,
      'birthCity': person.birthCity,
      'isDeceased': person.deathDate.trim().isNotEmpty,
      'photoUrl': person.photo.isEmpty ? null : person.photo,
      'generation': person.generation,
      'schemaVersion': memberSchemaVersion,
      'deletedAt': person.deletedAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMemberPrivate(
    Person person, {
    required String familyId,
    String? ownerUid,
    String? actorUid,
  }) {
    return {
      'memberId': person.id,
      'familyId': familyId,
      'ownerUid': ?_nullableIdentifier(ownerUid),
      'fullBirthDate': person.birthDate,
      'birthLastName': person.birthLastName,
      'originalLastName': person.originalLastName,
      'birthPlace': person.birthPlace,
      'birthCountry': person.birthCountry,
      'deathDate': person.deathDate,
      'deathPlace': person.deathPlace,
      'burialPlace': person.burialPlace,
      'publicMapLocation': person.publicMapLocation,
      'currentAddress': person.currentAddress,
      'currentCity': person.currentCity,
      'currentRegion': person.currentRegion,
      'currentCountry': person.currentCountry,
      'latitude': person.latitude,
      'longitude': person.longitude,
      'importantPlaces': person.importantPlaces
          .map((place) => place.toJson())
          .toList(),
      'email': person.email,
      'phone': person.phoneNumber,
      'whatsapp': person.whatsappNumber,
      'allowContact': person.allowContact,
      'emailVisibility': person.emailVisibility,
      'phoneVisibility': person.phoneVisibility,
      'whatsappVisibility': person.whatsappVisibility,
      'visibilitySettings': person.privacy.toJson(),
      'originFamilyId': person.originFamilyId,
      'linkedTreeEnabled': person.linkedTreeEnabled,
      'familyCode': person.familyCode,
      'marriageType': person.marriageType,
      'history': person.history.map((event) => event.toJson()).toList(),
      'privateNotes': person.notes,
      'isTemporaryProfile': person.isTemporaryProfile,
      'profileNeedsCompletion': person.profileNeedsCompletion,
      'version': person.version,
      'schemaVersion': memberSchemaVersion,
      'updatedBy': _nullableIdentifier(actorUid ?? person.updatedBy),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> publicPersonFromData(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final birthYear = _intValue(data['birthYear']);
    return {
      'id': documentId,
      'familyId': _stringValue(data['familyId']),
      'firstName': _stringValue(data['firstName']),
      'lastName': _stringValue(data['lastName']),
      'gender': _stringValue(data['gender']),
      'fatherId': _stringValue(data['fatherId']),
      'motherId': _stringValue(data['motherId']),
      'spouseIds': _stringList(data['spouseIds']),
      'childrenIds': _stringList(data['childrenIds']),
      'parents': _stringList(data['parents']),
      'spouses': _stringList(data['spouses']),
      'children': _stringList(data['children']),
      'birthDate': birthYear == null ? '' : '$birthYear',
      'birthCity': _stringValue(data['birthCity']),
      'photo': _stringValue(data['photoUrl']),
      'generation': _intValue(data['generation']) ?? 0,
      'deletedAt': _stringValue(data['deletedAt']),
    };
  }

  /// Temporary compatibility projection. It deliberately copies only fields
  /// admitted in the public member schema, regardless of legacy visibility
  /// flags or additional fields present in the old document.
  Map<String, dynamic> legacyPublicPersonFromData(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final birthYear = _yearFromDate(_stringValue(data['birthDate']));
    return publicPersonFromData({
      'familyId': data['familyId'],
      'firstName': data['firstName'],
      'lastName': data['lastName'],
      'gender': data['gender'],
      'fatherId': data['fatherId'],
      'motherId': data['motherId'],
      'spouseIds': data['spouseIds'],
      'childrenIds': data['childrenIds'],
      'parents': data['parents'],
      'spouses': data['spouses'],
      'children': data['children'],
      'birthYear': ?birthYear,
      'birthCity': data['birthCity'],
      'photoUrl': data['photo'],
      'generation': data['generation'],
      'deletedAt': data['deletedAt'],
    }, documentId: documentId);
  }

  Person enrichWithPrivateData(Person publicPerson, Map<String, dynamic> data) {
    return Person.fromJson({
      ...publicPerson.toJson(),
      'birthDate': _stringValue(data['fullBirthDate']),
      'birthLastName': _stringValue(data['birthLastName']),
      'originalLastName': _stringValue(data['originalLastName']),
      'birthPlace': _stringValue(data['birthPlace']),
      'birthCountry': _stringValue(data['birthCountry']),
      'deathDate': _stringValue(data['deathDate']),
      'deathPlace': _stringValue(data['deathPlace']),
      'burialPlace': _stringValue(data['burialPlace']),
      'publicMapLocation': _stringValue(data['publicMapLocation']),
      'currentAddress': _stringValue(data['currentAddress']),
      'currentCity': _stringValue(data['currentCity']),
      'currentRegion': _stringValue(data['currentRegion']),
      'currentCountry': _stringValue(data['currentCountry']),
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'importantPlaces': data['importantPlaces'],
      'email': _stringValue(data['email']),
      'phoneNumber': _stringValue(data['phone']),
      'whatsappNumber': _stringValue(data['whatsapp']),
      'allowContact': data['allowContact'],
      'emailVisibility': data['emailVisibility'],
      'phoneVisibility': data['phoneVisibility'],
      'whatsappVisibility': data['whatsappVisibility'],
      'privacy': data['visibilitySettings'],
      'originFamilyId': _stringValue(data['originFamilyId']),
      'linkedTreeEnabled': data['linkedTreeEnabled'],
      'familyCode': _stringValue(data['familyCode']),
      'marriageType': data['marriageType'],
      'history': data['history'],
      'notes': _stringValue(data['privateNotes']),
      'isTemporaryProfile': data['isTemporaryProfile'],
      'profileNeedsCompletion': data['profileNeedsCompletion'],
      'version': data['version'],
      'updatedAt': _normalizeValue(data['updatedAt']),
      'updatedBy': _stringValue(data['updatedBy']),
    });
  }

  int? _yearFromDate(String value) {
    final match = RegExp(r'^(\d{4})').firstMatch(value.trim());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? _intValue(Object? value) => value is num
      ? value.toInt()
      : value is String
      ? int.tryParse(value)
      : null;

  String _stringValue(Object? value) => value is String ? value : '';

  List<String> _stringList(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList(growable: false);

  String? _nullableIdentifier(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  Map<String, dynamic> toFirestore(
    Map<String, dynamic> json, {
    required String id,
    required String familyId,
  }) {
    return {
      ...json,
      'id': id,
      'familyId': familyId,
      'deletedAt': json['deletedAt'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPersonCreateData(
    Map<String, dynamic> json, {
    required String id,
    required String familyId,
    required String uid,
  }) {
    final sanitized = Map<String, dynamic>.from(json)
      ..remove('familyCode')
      ..removeWhere((key, value) => !_isFirestoreValue(value));
    return {
      ...sanitized,
      'id': id,
      'familyId': familyId,
      'version': 1,
      'schemaVersion': 1,
      'deletedAt': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    };
  }

  bool _isFirestoreValue(Object? value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is Timestamp ||
        value is FieldValue) {
      return true;
    }
    if (value is Map) {
      return value.keys.every((key) => key is String) &&
          value.values.every(_isFirestoreValue);
    }
    if (value is Iterable) return value.every(_isFirestoreValue);
    return false;
  }

  Map<String, dynamic> fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return {'id': doc.id, ..._normalize(doc.data() ?? const {})};
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> value) {
    return value.map((key, item) => MapEntry(key, _normalizeValue(item)));
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return _normalize(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}
