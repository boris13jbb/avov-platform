import 'managed_user.dart';

enum StudentGender {
  male('MALE'),
  female('FEMALE'),
  other('OTHER'),
  notSpecified('NOT_SPECIFIED');

  const StudentGender(this.apiValue);

  final String apiValue;

  static StudentGender fromApi(String? value) {
    for (final gender in StudentGender.values) {
      if (gender.apiValue == value) return gender;
    }
    return StudentGender.notSpecified;
  }

  String get label {
    switch (this) {
      case StudentGender.male:
        return 'Masculino';
      case StudentGender.female:
        return 'Femenino';
      case StudentGender.other:
        return 'Otro';
      case StudentGender.notSpecified:
        return 'No especificado';
    }
  }
}

class StudentUser {
  const StudentUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phone,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final UserAccountStatus status;
  final String? phone;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      status: UserAccountStatus.fromApi(json['status'] as String?),
      phone: json['phone'] as String?,
    );
  }
}

class ManagedStudent {
  const ManagedStudent({
    required this.id,
    required this.userId,
    required this.institutionId,
    required this.identification,
    required this.birthDate,
    required this.gender,
    required this.grade,
    this.parallel,
    this.representativeName,
    this.representativePhone,
    this.representativeEmail,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final int institutionId;
  final String identification;
  final DateTime birthDate;
  final StudentGender gender;
  final String grade;
  final String? parallel;
  final String? representativeName;
  final String? representativePhone;
  final String? representativeEmail;
  final StudentUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ManagedStudent.fromJson(Map<String, dynamic> json) {
    return ManagedStudent(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      institutionId: json['institution_id'] as int,
      identification: json['identification'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      gender: StudentGender.fromApi(json['gender'] as String?),
      grade: json['grade'] as String,
      parallel: json['parallel'] as String?,
      representativeName: json['representative_name'] as String?,
      representativePhone: json['representative_phone'] as String?,
      representativeEmail: json['representative_email'] as String?,
      user: StudentUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson({
    required int institutionId,
    required String password,
  }) {
    return {
      'institution_id': institutionId,
      'user': {
        'email': user.email.trim().toLowerCase(),
        'password': password,
        'first_name': user.firstName.trim(),
        'last_name': user.lastName.trim(),
        if (user.phone != null && user.phone!.isNotEmpty) 'phone': user.phone,
      },
      'identification': identification.trim().toUpperCase(),
      'birth_date': birthDate.toIso8601String().split('T').first,
      'gender': gender.apiValue,
      'grade': grade.trim(),
      if (parallel != null && parallel!.isNotEmpty) 'parallel': parallel,
      if (representativeName != null && representativeName!.isNotEmpty)
        'representative_name': representativeName,
      if (representativePhone != null && representativePhone!.isNotEmpty)
        'representative_phone': representativePhone,
      if (representativeEmail != null && representativeEmail!.isNotEmpty)
        'representative_email': representativeEmail,
      'status': user.status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'user': {
        'email': user.email.trim().toLowerCase(),
        'first_name': user.firstName.trim(),
        'last_name': user.lastName.trim(),
        'phone': user.phone,
      },
      'identification': identification.trim().toUpperCase(),
      'birth_date': birthDate.toIso8601String().split('T').first,
      'gender': gender.apiValue,
      'grade': grade.trim(),
      'parallel': parallel,
      'representative_name': representativeName,
      'representative_phone': representativePhone,
      'representative_email': representativeEmail,
    };
  }
}

class PaginatedStudents {
  const PaginatedStudents({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<ManagedStudent> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory PaginatedStudents.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedStudents(
      items: rawItems
          .map((item) => ManagedStudent.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
