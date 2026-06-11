import 'user_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.institutionId,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final int? institutionId;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromApi(json['role'] as String?);
    if (role == null) {
      throw FormatException('Rol de usuario no reconocido: ${json['role']}');
    }
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: role,
      institutionId: json['institution_id'] as int?,
    );
  }
}
