class FamilyCouncil {
  const FamilyCouncil({
    this.enabled = true,
    this.title = 'Conseil familial',
    this.description = 'Membres qui accompagnent le chef de famille.',
    this.members = const [],
  });

  final bool enabled;
  final String title;
  final String description;
  final List<FamilyCouncilMember> members;

  factory FamilyCouncil.fromJson(Map<String, dynamic> json) => FamilyCouncil(
    enabled: json['enabled'] as bool? ?? true,
    title: json['title'] as String? ?? 'Conseil familial',
    description:
        json['description'] as String? ??
        'Membres qui accompagnent le chef de famille.',
    members: (json['members'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              FamilyCouncilMember.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'title': title,
    'description': description,
    'members': members.map((member) => member.toJson()).toList(),
  };

  FamilyCouncil copyWith({
    bool? enabled,
    String? title,
    String? description,
    List<FamilyCouncilMember>? members,
  }) {
    return FamilyCouncil(
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      description: description ?? this.description,
      members: members ?? this.members,
    );
  }
}

class FamilyCouncilMember {
  const FamilyCouncilMember({
    required this.id,
    this.personId = '',
    this.firstName = '',
    this.lastName = '',
    this.roleTitle = '',
    this.residencePlace = '',
    this.email = '',
    this.phoneNumber = '',
    this.whatsappNumber = '',
    this.photo = '',
    this.active = true,
    this.order = 0,
    this.allowContact = true,
  });

  final String id;
  final String personId;
  final String firstName;
  final String lastName;
  final String roleTitle;
  final String residencePlace;
  final String email;
  final String phoneNumber;
  final String whatsappNumber;
  final String photo;
  final bool active;
  final int order;
  final bool allowContact;

  String get fullName => '$firstName $lastName'.trim();

  factory FamilyCouncilMember.fromJson(Map<String, dynamic> json) =>
      FamilyCouncilMember(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        roleTitle: json['roleTitle'] as String? ?? '',
        residencePlace: json['residencePlace'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        whatsappNumber: json['whatsappNumber'] as String? ?? '',
        photo: json['photo'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        order: json['order'] as int? ?? 0,
        allowContact: json['allowContact'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'firstName': firstName,
    'lastName': lastName,
    'roleTitle': roleTitle,
    'residencePlace': residencePlace,
    'email': email,
    'phoneNumber': phoneNumber,
    'whatsappNumber': whatsappNumber,
    'photo': photo,
    'active': active,
    'order': order,
    'allowContact': allowContact,
  };

  FamilyCouncilMember copyWith({
    String? id,
    String? personId,
    String? firstName,
    String? lastName,
    String? roleTitle,
    String? residencePlace,
    String? email,
    String? phoneNumber,
    String? whatsappNumber,
    String? photo,
    bool? active,
    int? order,
    bool? allowContact,
  }) {
    return FamilyCouncilMember(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      roleTitle: roleTitle ?? this.roleTitle,
      residencePlace: residencePlace ?? this.residencePlace,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      photo: photo ?? this.photo,
      active: active ?? this.active,
      order: order ?? this.order,
      allowContact: allowContact ?? this.allowContact,
    );
  }
}
