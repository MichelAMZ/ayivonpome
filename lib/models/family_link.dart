class FamilyLink {
  const FamilyLink({
    required this.id,
    this.fromPersonId = '',
    this.toPersonId = '',
    this.relationshipType = 'other',
    this.linkedFamilyCode = '',
    this.status = 'pending',
    this.notes = '',
  });

  final String id;
  final String fromPersonId;
  final String toPersonId;
  final String relationshipType;
  final String linkedFamilyCode;
  final String status;
  final String notes;

  factory FamilyLink.fromJson(Map<String, dynamic> json) => FamilyLink(
        id: json['id'] as String? ?? '',
        fromPersonId: json['fromPersonId'] as String? ?? '',
        toPersonId: json['toPersonId'] as String? ?? '',
        relationshipType: json['relationshipType'] as String? ?? 'other',
        linkedFamilyCode: json['linkedFamilyCode'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromPersonId': fromPersonId,
        'toPersonId': toPersonId,
        'relationshipType': relationshipType,
        'linkedFamilyCode': linkedFamilyCode,
        'status': status,
        'notes': notes,
      };

  FamilyLink copyWith({
    String? id,
    String? fromPersonId,
    String? toPersonId,
    String? relationshipType,
    String? linkedFamilyCode,
    String? status,
    String? notes,
  }) {
    return FamilyLink(
      id: id ?? this.id,
      fromPersonId: fromPersonId ?? this.fromPersonId,
      toPersonId: toPersonId ?? this.toPersonId,
      relationshipType: relationshipType ?? this.relationshipType,
      linkedFamilyCode: linkedFamilyCode ?? this.linkedFamilyCode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
