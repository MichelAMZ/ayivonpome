class Family {
  const Family({
    required this.id,
    required this.name,
    this.code = '',
    this.parentFamilyId = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String name;
  final String code;
  final String parentFamilyId;
  final String createdAt;
  final String updatedAt;

  factory Family.fromJson(Map<String, dynamic> json) => Family(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    parentFamilyId: json['parentFamilyId'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'parentFamilyId': parentFamilyId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
