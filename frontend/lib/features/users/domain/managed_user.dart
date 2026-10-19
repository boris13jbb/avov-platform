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
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final int? institutionId;
  final String? phone;

  String get fullName => '$firstName $lastName'.trim();

  String get roleLabel => userRoleLabel(role);

  String get statusLabel => userStatusLabel(status);

  bool get isActive => status == 'ACTIVE';

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final firstName = json['first_name'];
    final lastName = json['last_name'];
    final role = json['role'];
    final status = json['status'];
    if (id is! int ||
        email is! String ||
        firstName is! String ||
        lastName is! String ||
        role is! String ||
        status is! String) {
      throw const FormatException('Usuario incompleto');
    }
    final institutionId = json['institution_id'];
    return ManagedUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      status: status,
      institutionId: institutionId is int ? institutionId : null,
      phone: _text(json['phone']),
    );
  }
}

class ManagedUserPage {
  const ManagedUserPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<ManagedUser> items;
  final int total;
  final int page;
  final int pages;
}

class UserDraft {
  const UserDraft({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.password,
    this.institutionId,
    this.phone,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final String? password;
  final int? institutionId;
  final String? phone;

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'status': status,
      'phone': _emptyToNull(phone),
      'institution_id': role == 'SUPER_ADMIN' ? null : institutionId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone': _emptyToNull(phone),
      'institution_id': role == 'SUPER_ADMIN' ? null : institutionId,
    };
  }
}

class UserListQuery {
  const UserListQuery({
    required this.page,
    required this.pageSize,
    this.search,
    this.role,
    this.status,
    this.institutionId,
  });

  final int page;
  final int pageSize;
  final String? search;
  final String? role;
  final String? status;
  final int? institutionId;
}

const userRoles = <String>[
  'SUPER_ADMIN',
  'INSTITUTION_ADMIN',
  'COUNSELOR',
  'STUDENT',
];

const userStatuses = <String>['ACTIVE', 'INACTIVE', 'BLOCKED'];

String userRoleLabel(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return 'Superadministrador';
    case 'INSTITUTION_ADMIN':
      return 'Administrador de institución';
    case 'COUNSELOR':
      return 'Orientador';
    case 'STUDENT':
      return 'Estudiante';
    default:
      return role;
  }
}

String userStatusLabel(String status) {
  switch (status) {
    case 'ACTIVE':
      return 'Activa';
    case 'INACTIVE':
      return 'Inactiva';
    case 'BLOCKED':
      return 'Bloqueada';
    default:
      return status;
  }
}

String? _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

String? _emptyToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
