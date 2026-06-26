class MarriageRelation {
  const MarriageRelation({
    required this.id,
    required this.personId,
    required this.spouseId,
    this.marriageType = 'unknown',
    this.status = 'active',
    this.marriageDate = '',
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
        'marriagePlace': marriagePlace,
        'endDate': endDate,
        'notes': notes,
        'order': order,
      };
}
