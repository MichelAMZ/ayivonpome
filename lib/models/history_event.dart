class HistoryEvent {
  const HistoryEvent({
    required this.id,
    this.date = '',
    this.title = '',
    this.description = '',
    this.place = '',
    this.latitude,
    this.longitude,
    this.image = '',
  });

  final String id;
  final String date;
  final String title;
  final String description;
  final String place;
  final double? latitude;
  final double? longitude;
  final String image;

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => HistoryEvent(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        place: json['place'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        image: json['image'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'description': description,
        'place': place,
        'latitude': latitude,
        'longitude': longitude,
        'image': image,
      };

  HistoryEvent copyWith({
    String? id,
    String? date,
    String? title,
    String? description,
    String? place,
    double? latitude,
    double? longitude,
    String? image,
  }) {
    return HistoryEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      place: place ?? this.place,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      image: image ?? this.image,
    );
  }
}
