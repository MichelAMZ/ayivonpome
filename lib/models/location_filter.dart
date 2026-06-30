class LocationFilter {
  const LocationFilter({
    this.country = '',
    this.city = '',
    this.region = '',
    this.currentAddress = '',
    this.birthLocation = '',
    this.deathLocation = '',
    this.burialLocation = '',
    this.radiusAddress = '',
    this.generation,
    this.showOnlyResults = false,
    this.highlightResults = true,
  });

  final String country;
  final String city;
  final String region;
  final String currentAddress;
  final String birthLocation;
  final String deathLocation;
  final String burialLocation;
  final String radiusAddress;
  final int? generation;
  final bool showOnlyResults;
  final bool highlightResults;

  bool get isActive =>
      country.trim().isNotEmpty ||
      city.trim().isNotEmpty ||
      region.trim().isNotEmpty ||
      currentAddress.trim().isNotEmpty ||
      birthLocation.trim().isNotEmpty ||
      deathLocation.trim().isNotEmpty ||
      burialLocation.trim().isNotEmpty ||
      radiusAddress.trim().isNotEmpty ||
      generation != null;

  LocationFilter copyWith({
    String? country,
    String? city,
    String? region,
    String? currentAddress,
    String? birthLocation,
    String? deathLocation,
    String? burialLocation,
    String? radiusAddress,
    int? generation,
    bool clearGeneration = false,
    bool? showOnlyResults,
    bool? highlightResults,
  }) {
    return LocationFilter(
      country: country ?? this.country,
      city: city ?? this.city,
      region: region ?? this.region,
      currentAddress: currentAddress ?? this.currentAddress,
      birthLocation: birthLocation ?? this.birthLocation,
      deathLocation: deathLocation ?? this.deathLocation,
      burialLocation: burialLocation ?? this.burialLocation,
      radiusAddress: radiusAddress ?? this.radiusAddress,
      generation: clearGeneration ? null : generation ?? this.generation,
      showOnlyResults: showOnlyResults ?? this.showOnlyResults,
      highlightResults: highlightResults ?? this.highlightResults,
    );
  }
}
