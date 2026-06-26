class FamilyCode {
  const FamilyCode({
    required this.code,
    required this.familyName,
    required this.role,
    required this.status,
  });

  final String code;
  final String familyName;
  final String role;
  final String status;

  factory FamilyCode.fromJson(Map<String, dynamic> json) => FamilyCode(
        code: json['code'] as String? ?? '',
        familyName: json['familyName'] as String? ?? '',
        role: json['role'] as String? ?? 'viewer',
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'familyName': familyName,
        'role': role,
        'status': status,
      };

  FamilyCode copyWith({
    String? code,
    String? familyName,
    String? role,
    String? status,
  }) {
    return FamilyCode(
      code: code ?? this.code,
      familyName: familyName ?? this.familyName,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
}
