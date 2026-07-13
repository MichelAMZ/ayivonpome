class FamilyTreeReference {
  const FamilyTreeReference({
    required this.id,
    required this.personId,
    required this.sourceFamilyId,
    required this.targetFamilyId,
    required this.targetFamilyName,
    this.relationshipType = 'linkedFamily',
    this.enabled = true,
    this.createdAt = '',
  });

  final String id;
  final String personId;
  final String sourceFamilyId;
  final String targetFamilyId;
  final String targetFamilyName;
  final String relationshipType;
  final bool enabled;
  final String createdAt;

  factory FamilyTreeReference.fromJson(Map<String, dynamic> json) =>
      FamilyTreeReference(
        id: json['id'] as String? ?? '',
        personId: json['personId'] as String? ?? '',
        sourceFamilyId: json['sourceFamilyId'] as String? ?? '',
        targetFamilyId: json['targetFamilyId'] as String? ?? '',
        targetFamilyName: json['targetFamilyName'] as String? ?? '',
        relationshipType: json['relationshipType'] as String? ?? 'linkedFamily',
        enabled: json['enabled'] as bool? ?? true,
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'sourceFamilyId': sourceFamilyId,
    'targetFamilyId': targetFamilyId,
    'targetFamilyName': targetFamilyName,
    'relationshipType': relationshipType,
    'enabled': enabled,
    'createdAt': createdAt,
  };
}
