class MarriageRelation {
  const MarriageRelation({
    required this.id,
    required this.personId,
    required this.spouseId,
    this.familyId = '',
    this.marriageType = 'unknown',
    this.status = 'active',
    this.marriageDate = '',
    this.traditionalMarriageDate = '',
    this.civilMarriageDate = '',
    this.religiousMarriageDate = '',
    this.divorceDate = '',
    this.marriagePlace = '',
    this.marriageCountry = '',
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
  final String familyId;
  final String marriageType;
  final String status;
  final String marriageDate;
  final String traditionalMarriageDate;
  final String civilMarriageDate;
  final String religiousMarriageDate;
  final String divorceDate;
  final String marriagePlace;
  final String marriageCountry;
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
        personId:
            json['personId'] as String? ?? json['partner1Id'] as String? ?? '',
        spouseId:
            json['spouseId'] as String? ?? json['partner2Id'] as String? ?? '',
        familyId: json['familyId'] as String? ?? '',
        marriageType: _normalizeMarriageType(
          json['marriageType'] as String? ?? 'unknown',
        ),
        status: json['status'] as String? ?? 'active',
        marriageDate: json['marriageDate'] as String? ?? '',
        traditionalMarriageDate:
            json['traditionalMarriageDate'] as String? ??
            (json['marriageType'] == 'traditional' ||
                    json['marriageType'] == 'customary'
                ? json['marriageDate'] as String? ?? ''
                : ''),
        civilMarriageDate:
            json['civilMarriageDate'] as String? ??
            (json['marriageType'] == 'civil'
                ? json['marriageDate'] as String? ?? ''
                : ''),
        religiousMarriageDate:
            json['religiousMarriageDate'] as String? ??
            (json['marriageType'] == 'religious'
                ? json['marriageDate'] as String? ?? ''
                : ''),
        divorceDate: json['divorceDate'] as String? ?? '',
        marriagePlace: json['marriagePlace'] as String? ?? '',
        marriageCountry: json['marriageCountry'] as String? ?? '',
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
    'partner1Id': personId,
    'partner2Id': spouseId,
    'familyId': familyId,
    'marriageType': marriageType,
    'status': status,
    'marriageDate': marriageDate,
    'traditionalMarriageDate': traditionalMarriageDate,
    'civilMarriageDate': civilMarriageDate,
    'religiousMarriageDate': religiousMarriageDate,
    'divorceDate': divorceDate,
    'marriagePlace': marriagePlace,
    'marriageCountry': marriageCountry,
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
    String? familyId,
    String? marriageType,
    String? status,
    String? marriageDate,
    String? traditionalMarriageDate,
    String? civilMarriageDate,
    String? religiousMarriageDate,
    String? divorceDate,
    String? marriagePlace,
    String? marriageCountry,
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
      familyId: familyId ?? this.familyId,
      marriageType: marriageType ?? this.marriageType,
      status: status ?? this.status,
      marriageDate: marriageDate ?? this.marriageDate,
      traditionalMarriageDate:
          traditionalMarriageDate ?? this.traditionalMarriageDate,
      civilMarriageDate: civilMarriageDate ?? this.civilMarriageDate,
      religiousMarriageDate:
          religiousMarriageDate ?? this.religiousMarriageDate,
      divorceDate: divorceDate ?? this.divorceDate,
      marriagePlace: marriagePlace ?? this.marriagePlace,
      marriageCountry: marriageCountry ?? this.marriageCountry,
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

  String get partner1Id => personId;
  String get partner2Id => spouseId;

  bool involves(String personId) {
    return this.personId == personId || spouseId == personId;
  }

  String partnerOf(String personId) {
    if (this.personId == personId) return spouseId;
    if (spouseId == personId) return this.personId;
    return '';
  }

  static String _normalizeMarriageType(String value) {
    return switch (value) {
      'customary' => 'traditional',
      'married' => 'unknown',
      'partner' => 'freeUnion',
      'monogamy' => 'unknown',
      'polygamy' => 'unknown',
      _ => value,
    };
  }
}
