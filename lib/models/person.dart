import 'history_event.dart';
import 'important_place.dart';
import 'person_privacy.dart';

class Person {
  const Person({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.birthLastName = '',
    this.originalLastName = '',
    this.gender = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.deathDate = '',
    this.deathPlace = '',
    this.publicMapLocation = '',
    this.currentAddress = '',
    this.currentCity = '',
    this.currentRegion = '',
    this.currentCountry = '',
    this.birthCity = '',
    this.birthCountry = '',
    this.burialPlace = '',
    this.latitude,
    this.longitude,
    this.importantPlaces = const [],
    this.email = '',
    this.phoneNumber = '',
    this.whatsappNumber = '',
    this.allowContact = true,
    this.emailVisibility = 'familyOnly',
    this.phoneVisibility = 'familyOnly',
    this.whatsappVisibility = 'familyOnly',
    this.privacy = const PersonPrivacy(),
    this.photo = '',
    this.familyId = '',
    this.originFamilyId = '',
    this.linkedTreeEnabled = false,
    this.familyCode = '',
    this.fatherId = '',
    this.motherId = '',
    this.spouseIds = const [],
    this.childrenIds = const [],
    this.marriageType = 'unknown',
    this.parents = const [],
    this.spouses = const [],
    this.children = const [],
    this.history = const [],
    this.notes = '',
    this.generation = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.updatedBy = '',
    this.version = 1,
    this.deletedAt = '',
  });

  final String id;
  final String firstName;
  final String lastName;
  final String birthLastName;
  final String originalLastName;
  final String gender;
  final String birthDate;
  final String birthPlace;
  final String deathDate;
  final String deathPlace;
  final String publicMapLocation;
  final String currentAddress;
  final String currentCity;
  final String currentRegion;
  final String currentCountry;
  final String birthCity;
  final String birthCountry;
  final String burialPlace;
  final double? latitude;
  final double? longitude;
  final List<ImportantPlace> importantPlaces;
  final String email;
  final String phoneNumber;
  final String whatsappNumber;
  final bool allowContact;
  final String emailVisibility;
  final String phoneVisibility;
  final String whatsappVisibility;
  final PersonPrivacy privacy;
  final String photo;
  final String familyId;
  final String originFamilyId;
  final bool linkedTreeEnabled;
  final String familyCode;
  final String fatherId;
  final String motherId;
  final List<String> spouseIds;
  final List<String> childrenIds;
  final String marriageType;
  final List<String> parents;
  final List<String> spouses;
  final List<String> children;
  final List<HistoryEvent> history;
  final String notes;
  final int generation;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final int version;
  final String deletedAt;

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? id : value;
  }

  String get originLastName {
    final birthName = birthLastName.trim();
    if (birthName.isNotEmpty) return birthName;
    return originalLastName.trim();
  }

  bool get isFemale {
    final value = gender.toLowerCase().trim();
    return value == 'female' || value == 'f' || value == 'femme';
  }

  bool get shouldShowOriginLastName {
    final origin = originLastName;
    if (origin.isEmpty) return false;
    if (origin.toLowerCase() == lastName.trim().toLowerCase()) return false;
    return isFemale || originalLastName.trim().isNotEmpty;
  }

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    birthLastName: json['birthLastName'] as String? ?? '',
    originalLastName: json['originalLastName'] as String? ?? '',
    gender: json['gender'] as String? ?? '',
    birthDate: json['birthDate'] as String? ?? '',
    birthPlace: json['birthPlace'] as String? ?? '',
    deathDate: json['deathDate'] as String? ?? '',
    deathPlace: json['deathPlace'] as String? ?? '',
    publicMapLocation: json['publicMapLocation'] as String? ?? '',
    currentAddress: json['currentAddress'] as String? ?? '',
    currentCity: json['currentCity'] as String? ?? '',
    currentRegion: json['currentRegion'] as String? ?? '',
    currentCountry: json['currentCountry'] as String? ?? '',
    birthCity: json['birthCity'] as String? ?? '',
    birthCountry: json['birthCountry'] as String? ?? '',
    burialPlace: json['burialPlace'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    importantPlaces: (json['importantPlaces'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ImportantPlace.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    email: json['email'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    whatsappNumber: json['whatsappNumber'] as String? ?? '',
    allowContact: json['allowContact'] as bool? ?? true,
    emailVisibility: json['emailVisibility'] as String? ?? 'familyOnly',
    phoneVisibility: json['phoneVisibility'] as String? ?? 'familyOnly',
    whatsappVisibility: json['whatsappVisibility'] as String? ?? 'familyOnly',
    privacy: PersonPrivacy.fromJson(
      Map<String, dynamic>.from(json['privacy'] as Map? ?? const {}),
    ),
    photo: json['photo'] as String? ?? '',
    familyId: json['familyId'] as String? ?? '',
    originFamilyId: json['originFamilyId'] as String? ?? '',
    linkedTreeEnabled: json['linkedTreeEnabled'] as bool? ?? false,
    familyCode: json['familyCode'] as String? ?? '',
    fatherId: json['fatherId'] as String? ?? '',
    motherId: json['motherId'] as String? ?? '',
    spouseIds: List<String>.from(json['spouseIds'] as List? ?? const []),
    childrenIds: List<String>.from(json['childrenIds'] as List? ?? const []),
    marriageType: json['marriageType'] as String? ?? 'unknown',
    parents: List<String>.from(json['parents'] as List? ?? const []),
    spouses: List<String>.from(json['spouses'] as List? ?? const []),
    children: List<String>.from(json['children'] as List? ?? const []),
    history: (json['history'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => HistoryEvent.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    notes: json['notes'] as String? ?? '',
    generation: json['generation'] as int? ?? 0,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    updatedBy: json['updatedBy'] as String? ?? '',
    version: json['version'] as int? ?? 1,
    deletedAt: json['deletedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'birthLastName': birthLastName,
    'originalLastName': originalLastName,
    'gender': gender,
    'birthDate': birthDate,
    'birthPlace': birthPlace,
    'deathDate': deathDate,
    'deathPlace': deathPlace,
    'publicMapLocation': publicMapLocation,
    'currentAddress': currentAddress,
    'currentCity': currentCity,
    'currentRegion': currentRegion,
    'currentCountry': currentCountry,
    'birthCity': birthCity,
    'birthCountry': birthCountry,
    'burialPlace': burialPlace,
    'latitude': latitude,
    'longitude': longitude,
    'importantPlaces': importantPlaces.map((place) => place.toJson()).toList(),
    'email': email,
    'phoneNumber': phoneNumber,
    'whatsappNumber': whatsappNumber,
    'allowContact': allowContact,
    'emailVisibility': emailVisibility,
    'phoneVisibility': phoneVisibility,
    'whatsappVisibility': whatsappVisibility,
    'privacy': privacy.toJson(),
    'photo': photo,
    'familyId': familyId,
    'originFamilyId': originFamilyId,
    'linkedTreeEnabled': linkedTreeEnabled,
    'familyCode': familyCode,
    'fatherId': fatherId,
    'motherId': motherId,
    'spouseIds': spouseIds,
    'childrenIds': childrenIds,
    'marriageType': marriageType,
    'parents': parents,
    'spouses': spouses,
    'children': children,
    'history': history.map((event) => event.toJson()).toList(),
    'notes': notes,
    'generation': generation,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'version': version,
    'deletedAt': deletedAt,
  };

  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? birthLastName,
    String? originalLastName,
    String? gender,
    String? birthDate,
    String? birthPlace,
    String? deathDate,
    String? deathPlace,
    String? publicMapLocation,
    String? currentAddress,
    String? currentCity,
    String? currentRegion,
    String? currentCountry,
    String? birthCity,
    String? birthCountry,
    String? burialPlace,
    double? latitude,
    double? longitude,
    List<ImportantPlace>? importantPlaces,
    String? email,
    String? phoneNumber,
    String? whatsappNumber,
    bool? allowContact,
    String? emailVisibility,
    String? phoneVisibility,
    String? whatsappVisibility,
    PersonPrivacy? privacy,
    String? photo,
    String? familyId,
    String? originFamilyId,
    bool? linkedTreeEnabled,
    String? familyCode,
    String? fatherId,
    String? motherId,
    List<String>? spouseIds,
    List<String>? childrenIds,
    String? marriageType,
    List<String>? parents,
    List<String>? spouses,
    List<String>? children,
    List<HistoryEvent>? history,
    String? notes,
    int? generation,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    int? version,
    String? deletedAt,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthLastName: birthLastName ?? this.birthLastName,
      originalLastName: originalLastName ?? this.originalLastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      deathDate: deathDate ?? this.deathDate,
      deathPlace: deathPlace ?? this.deathPlace,
      publicMapLocation: publicMapLocation ?? this.publicMapLocation,
      currentAddress: currentAddress ?? this.currentAddress,
      currentCity: currentCity ?? this.currentCity,
      currentRegion: currentRegion ?? this.currentRegion,
      currentCountry: currentCountry ?? this.currentCountry,
      birthCity: birthCity ?? this.birthCity,
      birthCountry: birthCountry ?? this.birthCountry,
      burialPlace: burialPlace ?? this.burialPlace,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      importantPlaces: importantPlaces ?? this.importantPlaces,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      allowContact: allowContact ?? this.allowContact,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      whatsappVisibility: whatsappVisibility ?? this.whatsappVisibility,
      privacy: privacy ?? this.privacy,
      photo: photo ?? this.photo,
      familyId: familyId ?? this.familyId,
      originFamilyId: originFamilyId ?? this.originFamilyId,
      linkedTreeEnabled: linkedTreeEnabled ?? this.linkedTreeEnabled,
      familyCode: familyCode ?? this.familyCode,
      fatherId: fatherId ?? this.fatherId,
      motherId: motherId ?? this.motherId,
      spouseIds: spouseIds ?? this.spouseIds,
      childrenIds: childrenIds ?? this.childrenIds,
      marriageType: marriageType ?? this.marriageType,
      parents: parents ?? this.parents,
      spouses: spouses ?? this.spouses,
      children: children ?? this.children,
      history: history ?? this.history,
      notes: notes ?? this.notes,
      generation: generation ?? this.generation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
