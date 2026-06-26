class PersonPrivacy {
  const PersonPrivacy({
    this.showMapInPublicMode = true,
    this.showBirthPlaceInPublicMode = false,
    this.showCurrentAddressInPublicMode = false,
    this.showContactInPublicMode = false,
    this.showHistoryInPublicMode = false,
  });

  final bool showMapInPublicMode;
  final bool showBirthPlaceInPublicMode;
  final bool showCurrentAddressInPublicMode;
  final bool showContactInPublicMode;
  final bool showHistoryInPublicMode;

  factory PersonPrivacy.fromJson(Map<String, dynamic> json) => PersonPrivacy(
        showMapInPublicMode: json['showMapInPublicMode'] as bool? ?? true,
        showBirthPlaceInPublicMode:
            json['showBirthPlaceInPublicMode'] as bool? ?? false,
        showCurrentAddressInPublicMode:
            json['showCurrentAddressInPublicMode'] as bool? ?? false,
        showContactInPublicMode:
            json['showContactInPublicMode'] as bool? ?? false,
        showHistoryInPublicMode:
            json['showHistoryInPublicMode'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'showMapInPublicMode': showMapInPublicMode,
        'showBirthPlaceInPublicMode': showBirthPlaceInPublicMode,
        'showCurrentAddressInPublicMode': showCurrentAddressInPublicMode,
        'showContactInPublicMode': showContactInPublicMode,
        'showHistoryInPublicMode': showHistoryInPublicMode,
      };
}
