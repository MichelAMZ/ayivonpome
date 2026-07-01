class FamilyLink {
  const FamilyLink({
    required this.id,
    this.fromPersonId = '',
    this.toPersonId = '',
    this.relationshipType = 'other',
    this.linkedFamilyCode = '',
    this.status = 'pending',
    this.notes = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.updatedBy = '',
    this.version = 1,
    this.deletedAt = '',
  });

  final String id;
  final String fromPersonId;
  final String toPersonId;
  final String relationshipType;
  final String linkedFamilyCode;
  final String status;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final int version;
  final String deletedAt;

  factory FamilyLink.fromJson(Map<String, dynamic> json) => FamilyLink(
    id: json['id'] as String? ?? '',
    fromPersonId: json['fromPersonId'] as String? ?? '',
    toPersonId: json['toPersonId'] as String? ?? '',
    relationshipType: json['relationshipType'] as String? ?? 'other',
    linkedFamilyCode: json['linkedFamilyCode'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    notes: json['notes'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    updatedBy: json['updatedBy'] as String? ?? '',
    version: json['version'] as int? ?? 1,
    deletedAt: json['deletedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromPersonId': fromPersonId,
    'toPersonId': toPersonId,
    'relationshipType': relationshipType,
    'linkedFamilyCode': linkedFamilyCode,
    'status': status,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'version': version,
    'deletedAt': deletedAt,
  };

  FamilyLink copyWith({
    String? id,
    String? fromPersonId,
    String? toPersonId,
    String? relationshipType,
    String? linkedFamilyCode,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    int? version,
    String? deletedAt,
  }) {
    return FamilyLink(
      id: id ?? this.id,
      fromPersonId: fromPersonId ?? this.fromPersonId,
      toPersonId: toPersonId ?? this.toPersonId,
      relationshipType: relationshipType ?? this.relationshipType,
      linkedFamilyCode: linkedFamilyCode ?? this.linkedFamilyCode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
