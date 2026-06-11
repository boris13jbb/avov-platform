import 'user_role.dart';

enum UserAccountStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  blocked('BLOCKED');

  const UserAccountStatus(this.apiValue);

  final String apiValue;

  static UserAccountStatus fromApi(String? value) {
    for (final status in UserAccountStatus.values) {
      if (status.apiValue == value) return status;
    }
    return UserAccountStatus.active;
  }

  String get label {
    switch (this) {
      case UserAccountStatus.active:
        return 'Activo';
      case UserAccountStatus.inactive:
        return 'Inactivo';
      case UserAccountStatus.blocked:
        return 'Bloqueado';
    }
  }
}

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.institutionId,
    this.phone,
    this.avatarUrl,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserAccountStatus status;
  final int? institutionId;
  final String? phone;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromApi(json['role'] as String?);
    if (role == null) {
      throw FormatException('Rol no reconocido: ${json['role']}');
    }
    return ManagedUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: role,
      status: UserAccountStatus.fromApi(json['status'] as String?),
      institutionId: json['institution_id'] as int?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson({
    required String password,
  }) {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'role': role.apiValue,
      if (role != UserRole.superAdmin && institutionId != null)
        'institution_id': institutionId,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'status': status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'email': email.trim().toLowerCase(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'role': role.apiValue,
      if (role != UserRole.superAdmin) 'institution_id': institutionId,
      'phone': phone,
    };
  }
}

class PaginatedUsers {
  const PaginatedUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<ManagedUser> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedUsers(
      items: rawItems
          .map((item) => ManagedUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
