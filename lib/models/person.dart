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
    this.isTemporaryProfile = false,
    this.profileNeedsCompletion = false,
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
  final bool isTemporaryProfile;
  final bool profileNeedsCompletion;

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
    id: _stringValue(json['id']),
    firstName: _stringValue(json['firstName']),
    lastName: _stringValue(json['lastName']),
    birthLastName: _stringValue(json['birthLastName']),
    originalLastName: _stringValue(json['originalLastName']),
    gender: _stringValue(json['gender']),
    birthDate: _stringValue(json['birthDate']),
    birthPlace: _stringValue(json['birthPlace']),
    deathDate: _stringValue(json['deathDate']),
    deathPlace: _stringValue(json['deathPlace']),
    publicMapLocation: _stringValue(json['publicMapLocation']),
    currentAddress: _stringValue(json['currentAddress']),
    currentCity: _stringValue(json['currentCity']),
    currentRegion: _stringValue(json['currentRegion']),
    currentCountry: _stringValue(json['currentCountry']),
    birthCity: _stringValue(json['birthCity']),
    birthCountry: _stringValue(json['birthCountry']),
    burialPlace: _stringValue(json['burialPlace']),
    latitude: _doubleValue(json['latitude']),
    longitude: _doubleValue(json['longitude']),
    importantPlaces: _listValue(json['importantPlaces'])
        .whereType<Map>()
        .map((item) => ImportantPlace.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    email: _stringValue(json['email']),
    phoneNumber: _stringValue(json['phoneNumber']),
    whatsappNumber: _stringValue(json['whatsappNumber']),
    allowContact: _boolValue(json['allowContact'], fallback: true),
    emailVisibility: _stringValue(
      json['emailVisibility'],
      fallback: 'familyOnly',
    ),
    phoneVisibility: _stringValue(
      json['phoneVisibility'],
      fallback: 'familyOnly',
    ),
    whatsappVisibility: _stringValue(
      json['whatsappVisibility'],
      fallback: 'familyOnly',
    ),
    privacy: PersonPrivacy.fromJson(_mapValue(json['privacy'])),
    photo: _stringValue(json['photo']),
    familyId: _stringValue(json['familyId']),
    originFamilyId: _stringValue(json['originFamilyId']),
    linkedTreeEnabled: _boolValue(json['linkedTreeEnabled']),
    familyCode: _stringValue(json['familyCode']),
    fatherId: _stringValue(json['fatherId']),
    motherId: _stringValue(json['motherId']),
    spouseIds: _stringList(json['spouseIds']),
    childrenIds: _stringList(json['childrenIds']),
    marriageType: _stringValue(json['marriageType'], fallback: 'unknown'),
    parents: _stringList(json['parents']),
    spouses: _stringList(json['spouses']),
    children: _stringList(json['children']),
    history: _listValue(json['history'])
        .whereType<Map>()
        .map((item) => HistoryEvent.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    notes: _stringValue(json['notes']),
    generation: _intValue(json['generation']),
    createdAt: _stringValue(json['createdAt']),
    updatedAt: _stringValue(json['updatedAt']),
    updatedBy: _stringValue(json['updatedBy']),
    version: _intValue(json['version'], fallback: 1),
    deletedAt: _stringValue(json['deletedAt']),
    isTemporaryProfile: _boolValue(json['isTemporaryProfile']),
    profileNeedsCompletion: _boolValue(json['profileNeedsCompletion']),
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
    'isTemporaryProfile': isTemporaryProfile,
    'profileNeedsCompletion': profileNeedsCompletion,
  };

  Map<String, dynamic> toPublicJson() {
    final visible = privacy.copyWith(showMapInPublicMode: true);
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'publicMapLocation': publicMapLocation,
      if (visible.photoVisible) 'photo': photo,
      if (visible.genderVisible) 'gender': gender,
      if (visible.birthLastNameVisible) 'birthLastName': birthLastName,
      if (visible.birthDateVisible) 'birthDate': birthDate,
      if (visible.showBirthPlaceInPublicMode) 'birthPlace': birthPlace,
      if (visible.deathDateVisible) 'deathDate': deathDate,
      if (visible.deathPlaceVisible) 'deathPlace': deathPlace,
      if (visible.burialPlaceVisible) 'burialPlace': burialPlace,
      if (visible.showCurrentAddressInPublicMode)
        'currentAddress': currentAddress,
      if (visible.privateCoordinatesVisible) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      if (visible.familyBranchVisible) 'familyCode': familyCode,
      if (visible.familyRelationsVisible) ...{
        'fatherId': fatherId,
        'motherId': motherId,
        'spouseIds': spouseIds,
        'childrenIds': childrenIds,
        'parents': parents,
        'spouses': spouses,
        'children': children,
      },
      if (visible.emailVisible) 'email': email,
      if (visible.phoneVisible) 'phoneNumber': phoneNumber,
      if (visible.whatsappVisible) 'whatsappNumber': whatsappNumber,
      if (visible.showHistoryInPublicMode) 'history': history,
      if (visible.notesVisible) 'notes': notes,
    };
  }

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
    bool? isTemporaryProfile,
    bool? profileNeedsCompletion,
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
      isTemporaryProfile: isTemporaryProfile ?? this.isTemporaryProfile,
      profileNeedsCompletion:
          profileNeedsCompletion ?? this.profileNeedsCompletion,
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

bool _boolValue(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

int _intValue(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;

double? _doubleValue(Object? value) => value is num ? value.toDouble() : null;

List<dynamic> _listValue(Object? value) =>
    value is List ? value : const <dynamic>[];

List<String> _stringList(Object? value) =>
    _listValue(value).whereType<String>().toList(growable: false);

Map<String, dynamic> _mapValue(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
