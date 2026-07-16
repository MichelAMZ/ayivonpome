class PersonPrivacy {
  const PersonPrivacy({
    this.showMapInPublicMode = true,
    this.showBirthPlaceInPublicMode = false,
    this.showCurrentAddressInPublicMode = false,
    this.showContactInPublicMode = false,
    this.showHistoryInPublicMode = false,
    this.photoVisible = true,
    this.genderVisible = true,
    this.birthLastNameVisible = true,
    this.birthDateVisible = true,
    this.deathDateVisible = true,
    this.deathPlaceVisible = false,
    this.burialPlaceVisible = false,
    this.privateCoordinatesVisible = false,
    this.familyBranchVisible = true,
    this.familyRelationsVisible = false,
    this.emailVisible = false,
    this.phoneVisible = false,
    this.whatsappVisible = false,
    this.notesVisible = false,
  });

  final bool showMapInPublicMode;
  final bool showBirthPlaceInPublicMode;
  final bool showCurrentAddressInPublicMode;
  final bool showContactInPublicMode;
  final bool showHistoryInPublicMode;
  final bool photoVisible;
  final bool genderVisible;
  final bool birthLastNameVisible;
  final bool birthDateVisible;
  final bool deathDateVisible;
  final bool deathPlaceVisible;
  final bool burialPlaceVisible;
  final bool privateCoordinatesVisible;
  final bool familyBranchVisible;
  final bool familyRelationsVisible;
  final bool emailVisible;
  final bool phoneVisible;
  final bool whatsappVisible;
  final bool notesVisible;

  factory PersonPrivacy.fromJson(Map<String, dynamic> json) => PersonPrivacy(
    showMapInPublicMode: json['showMapInPublicMode'] as bool? ?? true,
    showBirthPlaceInPublicMode:
        json['showBirthPlaceInPublicMode'] as bool? ?? false,
    showCurrentAddressInPublicMode:
        json['showCurrentAddressInPublicMode'] as bool? ?? false,
    showContactInPublicMode: json['showContactInPublicMode'] as bool? ?? false,
    showHistoryInPublicMode: json['showHistoryInPublicMode'] as bool? ?? false,
    photoVisible: json['photoVisible'] as bool? ?? true,
    genderVisible: json['genderVisible'] as bool? ?? true,
    birthLastNameVisible: json['birthLastNameVisible'] as bool? ?? true,
    birthDateVisible: json['birthDateVisible'] as bool? ?? true,
    deathDateVisible: json['deathDateVisible'] as bool? ?? true,
    deathPlaceVisible: json['deathPlaceVisible'] as bool? ?? false,
    burialPlaceVisible: json['burialPlaceVisible'] as bool? ?? false,
    privateCoordinatesVisible:
        json['privateCoordinatesVisible'] as bool? ?? false,
    familyBranchVisible: json['familyBranchVisible'] as bool? ?? true,
    familyRelationsVisible: json['familyRelationsVisible'] as bool? ?? false,
    emailVisible: json['emailVisible'] as bool? ?? false,
    phoneVisible: json['phoneVisible'] as bool? ?? false,
    whatsappVisible: json['whatsappVisible'] as bool? ?? false,
    notesVisible: json['notesVisible'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'showMapInPublicMode': showMapInPublicMode,
    'showBirthPlaceInPublicMode': showBirthPlaceInPublicMode,
    'showCurrentAddressInPublicMode': showCurrentAddressInPublicMode,
    'showContactInPublicMode': showContactInPublicMode,
    'showHistoryInPublicMode': showHistoryInPublicMode,
    'photoVisible': photoVisible,
    'genderVisible': genderVisible,
    'birthLastNameVisible': birthLastNameVisible,
    'birthDateVisible': birthDateVisible,
    'deathDateVisible': deathDateVisible,
    'deathPlaceVisible': deathPlaceVisible,
    'burialPlaceVisible': burialPlaceVisible,
    'privateCoordinatesVisible': privateCoordinatesVisible,
    'familyBranchVisible': familyBranchVisible,
    'familyRelationsVisible': familyRelationsVisible,
    'emailVisible': emailVisible,
    'phoneVisible': phoneVisible,
    'whatsappVisible': whatsappVisible,
    'notesVisible': notesVisible,
  };

  PersonPrivacy copyWith({
    bool? showMapInPublicMode,
    bool? showBirthPlaceInPublicMode,
    bool? showCurrentAddressInPublicMode,
    bool? showContactInPublicMode,
    bool? showHistoryInPublicMode,
    bool? photoVisible,
    bool? genderVisible,
    bool? birthLastNameVisible,
    bool? birthDateVisible,
    bool? deathDateVisible,
    bool? deathPlaceVisible,
    bool? burialPlaceVisible,
    bool? privateCoordinatesVisible,
    bool? familyBranchVisible,
    bool? familyRelationsVisible,
    bool? emailVisible,
    bool? phoneVisible,
    bool? whatsappVisible,
    bool? notesVisible,
  }) {
    return PersonPrivacy(
      showMapInPublicMode: showMapInPublicMode ?? true,
      showBirthPlaceInPublicMode:
          showBirthPlaceInPublicMode ?? this.showBirthPlaceInPublicMode,
      showCurrentAddressInPublicMode:
          showCurrentAddressInPublicMode ?? this.showCurrentAddressInPublicMode,
      showContactInPublicMode:
          showContactInPublicMode ?? this.showContactInPublicMode,
      showHistoryInPublicMode:
          showHistoryInPublicMode ?? this.showHistoryInPublicMode,
      photoVisible: photoVisible ?? this.photoVisible,
      genderVisible: genderVisible ?? this.genderVisible,
      birthLastNameVisible: birthLastNameVisible ?? this.birthLastNameVisible,
      birthDateVisible: birthDateVisible ?? this.birthDateVisible,
      deathDateVisible: deathDateVisible ?? this.deathDateVisible,
      deathPlaceVisible: deathPlaceVisible ?? this.deathPlaceVisible,
      burialPlaceVisible: burialPlaceVisible ?? this.burialPlaceVisible,
      privateCoordinatesVisible:
          privateCoordinatesVisible ?? this.privateCoordinatesVisible,
      familyBranchVisible: familyBranchVisible ?? this.familyBranchVisible,
      familyRelationsVisible:
          familyRelationsVisible ?? this.familyRelationsVisible,
      emailVisible: emailVisible ?? this.emailVisible,
      phoneVisible: phoneVisible ?? this.phoneVisible,
      whatsappVisible: whatsappVisible ?? this.whatsappVisible,
      notesVisible: notesVisible ?? this.notesVisible,
    );
  }

  PersonPrivacy hideSensitive() => copyWith(
    showMapInPublicMode: true,
    showCurrentAddressInPublicMode: false,
    showContactInPublicMode: false,
    showHistoryInPublicMode: false,
    privateCoordinatesVisible: false,
    familyRelationsVisible: false,
    emailVisible: false,
    phoneVisible: false,
    whatsappVisible: false,
    notesVisible: false,
  );
}
