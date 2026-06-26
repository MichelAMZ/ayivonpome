class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.email = '',
    this.phoneNumber = '',
    this.whatsappNumber = '',
    this.active = true,
  });

  final String id;
  final String fullName;
  final String role;
  final String email;
  final String phoneNumber;
  final String whatsappNumber;
  final bool active;

  bool get isSuperAdmin => role == 'superAdmin';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? 'admin',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        whatsappNumber: json['whatsappNumber'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'role': role,
        'email': email,
        'phoneNumber': phoneNumber,
        'whatsappNumber': whatsappNumber,
        'active': active,
      };
}
