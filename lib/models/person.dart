import 'history_event.dart';
import 'important_place.dart';
import 'person_privacy.dart';

class Person {
  const Person({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.deathDate = '',
    this.deathPlace = '',
    this.publicMapLocation = '',
    this.currentAddress = '',
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
  });

  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String birthDate;
  final String birthPlace;
  final String deathDate;
  final String deathPlace;
  final String publicMapLocation;
  final String currentAddress;
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

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? id : value;
  }

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        birthDate: json['birthDate'] as String? ?? '',
        birthPlace: json['birthPlace'] as String? ?? '',
        deathDate: json['deathDate'] as String? ?? '',
        deathPlace: json['deathPlace'] as String? ?? '',
        publicMapLocation: json['publicMapLocation'] as String? ?? '',
        currentAddress: json['currentAddress'] as String? ?? '',
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'deathDate': deathDate,
        'deathPlace': deathPlace,
        'publicMapLocation': publicMapLocation,
        'currentAddress': currentAddress,
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
      };

  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? birthPlace,
    String? deathDate,
    String? deathPlace,
    String? publicMapLocation,
    String? currentAddress,
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
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      deathDate: deathDate ?? this.deathDate,
      deathPlace: deathPlace ?? this.deathPlace,
      publicMapLocation: publicMapLocation ?? this.publicMapLocation,
      currentAddress: currentAddress ?? this.currentAddress,
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
    );
  }
}
