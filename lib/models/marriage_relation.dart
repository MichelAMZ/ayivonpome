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
    this.createdAt = '',
    this.updatedAt = '',
    this.updatedBy = '',
    this.version = 1,
    this.deletedAt = '',
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
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final int version;
  final String deletedAt;

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
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        updatedBy: json['updatedBy'] as String? ?? '',
        version: json['version'] as int? ?? 1,
        deletedAt: json['deletedAt'] as String? ?? '',
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
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'version': version,
    'deletedAt': deletedAt,
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
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    int? version,
    String? deletedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
