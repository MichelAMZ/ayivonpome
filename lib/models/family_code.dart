import 'family_history.dart';

class FamilyCode {
  const FamilyCode({
    required this.code,
    required this.familyName,
    required this.role,
    required this.status,
    this.history = const FamilyHistory(maxCharacters: 3000),
  });

  final String code;
  final String familyName;
  final String role;
  final String status;
  final FamilyHistory history;

  factory FamilyCode.fromJson(Map<String, dynamic> json) => FamilyCode(
    code: json['code'] as String? ?? '',
    familyName: json['familyName'] as String? ?? '',
    role: json['role'] as String? ?? 'viewer',
    status: json['status'] as String? ?? 'pending',
    history: FamilyHistory.fromJson(
      Map<String, dynamic>.from(json['history'] as Map? ?? const {}),
      defaultMaxCharacters: 3000,
    ),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'familyName': familyName,
    'role': role,
    'status': status,
    'history': history.toJson(),
  };

  FamilyCode copyWith({
    String? code,
    String? familyName,
    String? role,
    String? status,
    FamilyHistory? history,
  }) {
    return FamilyCode(
      code: code ?? this.code,
      familyName: familyName ?? this.familyName,
      role: role ?? this.role,
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }
}
