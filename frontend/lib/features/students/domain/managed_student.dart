import '../../users/domain/managed_user.dart';

class ManagedStudent {
  const ManagedStudent({
    required this.id,
    required this.userId,
    required this.institutionId,
    required this.identification,
    required this.birthDate,
    required this.gender,
    required this.grade,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phone,
    this.parallel,
    this.representativeName,
    this.representativePhone,
    this.representativeEmail,
  });

  final int id;
  final int userId;
  final int institutionId;
  final String identification;
  final String birthDate;
  final String gender;
  final String grade;
  final String email;
  final String firstName;
  final String lastName;
  final String status;
  final String? phone;
  final String? parallel;
  final String? representativeName;
  final String? representativePhone;
  final String? representativeEmail;

  String get fullName => '$firstName $lastName'.trim();

  String get genderLabel => studentGenderLabel(gender);

  String get statusLabel => userStatusLabel(status);

  bool get isActive => status == 'ACTIVE';

  factory ManagedStudent.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'];
    final institutionId = json['institution_id'];
    final identification = json['identification'];
    final birthDate = json['birth_date'];
    final gender = json['gender'];
    final grade = json['grade'];
    final user = json['user'];
    if (id is! int ||
        userId is! int ||
        institutionId is! int ||
        identification is! String ||
        birthDate is! String ||
        gender is! String ||
        grade is! String ||
        user is! Map) {
      throw const FormatException('Estudiante incompleto');
    }
    final profile = Map<String, dynamic>.from(user);
    final email = profile['email'];
    final firstName = profile['first_name'];
    final lastName = profile['last_name'];
    final status = profile['status'];
    if (email is! String ||
        firstName is! String ||
        lastName is! String ||
        status is! String) {
      throw const FormatException('Estudiante incompleto');
    }
    return ManagedStudent(
      id: id,
      userId: userId,
      institutionId: institutionId,
      identification: identification,
      birthDate: birthDate.length >= 10 ? birthDate.substring(0, 10) : birthDate,
      gender: gender,
      grade: grade,
      email: email,
      firstName: firstName,
      lastName: lastName,
      status: status,
      phone: _text(profile['phone']),
      parallel: _text(json['parallel']),
      representativeName: _text(json['representative_name']),
      representativePhone: _text(json['representative_phone']),
      representativeEmail: _text(json['representative_email']),
    );
  }
}

class ManagedStudentPage {
  const ManagedStudentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<ManagedStudent> items;
  final int total;
  final int page;
  final int pages;
}

class StudentDraft {
  const StudentDraft({
    required this.institutionId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.identification,
    required this.birthDate,
    required this.gender,
    required this.grade,
    required this.status,
    this.password,
    this.phone,
    this.parallel,
    this.representativeName,
    this.representativePhone,
    this.representativeEmail,
  });

  final int institutionId;
  final String email;
  final String firstName;
  final String lastName;
  final String identification;
  final String birthDate;
  final String gender;
  final String grade;
  final String status;
  final String? password;
  final String? phone;
  final String? parallel;
  final String? representativeName;
  final String? representativePhone;
  final String? representativeEmail;

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'institution_id': institutionId,
      'user': <String, dynamic>{
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': _emptyToNull(phone),
      },
      'identification': identification.trim().toUpperCase(),
      'birth_date': birthDate,
      'gender': gender,
      'grade': grade.trim(),
      'parallel': _emptyToNull(parallel),
      'representative_name': _emptyToNull(representativeName),
      'representative_phone': _emptyToNull(representativePhone),
      'representative_email': _emptyToNull(representativeEmail),
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'user': <String, dynamic>{
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': _emptyToNull(phone),
      },
      'identification': identification.trim().toUpperCase(),
      'birth_date': birthDate,
      'gender': gender,
      'grade': grade.trim(),
      'parallel': _emptyToNull(parallel),
      'representative_name': _emptyToNull(representativeName),
      'representative_phone': _emptyToNull(representativePhone),
      'representative_email': _emptyToNull(representativeEmail),
    };
  }
}

class StudentListQuery {
  const StudentListQuery({
    required this.page,
    required this.pageSize,
    this.search,
    this.institutionId,
    this.status,
    this.grade,
    this.gender,
  });

  final int page;
  final int pageSize;
  final String? search;
  final int? institutionId;
  final String? status;
  final String? grade;
  final String? gender;
}

const studentGenders = <String>[
  'FEMALE',
  'MALE',
  'OTHER',
  'NOT_SPECIFIED',
];

String studentGenderLabel(String gender) {
  switch (gender) {
    case 'FEMALE':
      return 'Femenino';
    case 'MALE':
      return 'Masculino';
    case 'OTHER':
      return 'Otro';
    case 'NOT_SPECIFIED':
      return 'No especificado';
    default:
      return gender;
  }
}

bool canManageStudents(String? role) {
  return role == 'SUPER_ADMIN' || role == 'INSTITUTION_ADMIN';
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
