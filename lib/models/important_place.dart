class ImportantPlace {
  const ImportantPlace({
    this.name = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.description = '',
  });

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String description;

  factory ImportantPlace.fromJson(Map<String, dynamic> json) => ImportantPlace(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };
}
