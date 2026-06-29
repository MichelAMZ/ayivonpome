class MarriageRelation {
  const MarriageRelation({
    required this.id,
    required this.personId,
    required this.spouseId,
    this.marriageType = 'unknown',
    this.status = 'active',
    this.marriageDate = '',
    this.divorceDate = '',
    this.marriagePlace = '',
    this.endDate = '',
    this.notes = '',
    this.order = 1,
  });

  final String id;
  final String personId;
  final String spouseId;
  final String marriageType;
  final String status;
  final String marriageDate;
  final String divorceDate;
  final String marriagePlace;
  final String endDate;
  final String notes;
  final int order;

  factory MarriageRelation.fromJson(Map<String, dynamic> json) =>
      MarriageRelation(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        spouseId: json['spouseId'] as String? ?? '',
        marriageType: json['marriageType'] as String? ?? 'unknown',
        status: json['status'] as String? ?? 'active',
        marriageDate: json['marriageDate'] as String? ?? '',
        divorceDate: json['divorceDate'] as String? ?? '',
        marriagePlace: json['marriagePlace'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        order: json['order'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'spouseId': spouseId,
    'marriageType': marriageType,
    'status': status,
    'marriageDate': marriageDate,
    'divorceDate': divorceDate,
    'marriagePlace': marriagePlace,
    'endDate': endDate,
    'notes': notes,
    'order': order,
  };

  MarriageRelation copyWith({
    String? id,
    String? personId,
    String? spouseId,
    String? marriageType,
    String? status,
    String? marriageDate,
    String? divorceDate,
    String? marriagePlace,
    String? endDate,
    String? notes,
    int? order,
  }) {
    return MarriageRelation(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      spouseId: spouseId ?? this.spouseId,
      marriageType: marriageType ?? this.marriageType,
      status: status ?? this.status,
      marriageDate: marriageDate ?? this.marriageDate,
      divorceDate: divorceDate ?? this.divorceDate,
      marriagePlace: marriagePlace ?? this.marriagePlace,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}
