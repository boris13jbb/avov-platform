enum CareerStatus {
  active('ACTIVE'),
  inactive('INACTIVE');

  const CareerStatus(this.apiValue);

  final String apiValue;

  static CareerStatus fromApi(String? value) {
    for (final status in CareerStatus.values) {
      if (status.apiValue == value) return status;
    }
    return CareerStatus.active;
  }

  String get label {
    switch (this) {
      case CareerStatus.active:
        return 'Activa';
      case CareerStatus.inactive:
        return 'Inactiva';
    }
  }
}

enum DegreeType {
  tecnologico('TECNOLOGICO'),
  tercerNivel('TERCER_NIVEL'),
  licenciatura('LICENCIATURA'),
  ingenieria('INGENIERIA'),
  otro('OTRO');

  const DegreeType(this.apiValue);

  final String apiValue;

  static DegreeType fromApi(String? value) {
    for (final item in DegreeType.values) {
      if (item.apiValue == value) return item;
    }
    return DegreeType.otro;
  }

  String get label {
    switch (this) {
      case DegreeType.tecnologico:
        return 'Tecnológico';
      case DegreeType.tercerNivel:
        return 'Tercer nivel';
      case DegreeType.licenciatura:
        return 'Licenciatura';
      case DegreeType.ingenieria:
        return 'Ingeniería';
      case DegreeType.otro:
        return 'Otro';
    }
  }
}

enum CareerInstitutionType {
  publica('PUBLICA'),
  privada('PRIVADA'),
  ambas('AMBAS');

  const CareerInstitutionType(this.apiValue);

  final String apiValue;

  static CareerInstitutionType fromApi(String? value) {
    for (final item in CareerInstitutionType.values) {
      if (item.apiValue == value) return item;
    }
    return CareerInstitutionType.ambas;
  }

  String get label {
    switch (this) {
      case CareerInstitutionType.publica:
        return 'Pública';
      case CareerInstitutionType.privada:
        return 'Privada';
      case CareerInstitutionType.ambas:
        return 'Ambas';
    }
  }
}

class Career {
  const Career({
    required this.id,
    required this.name,
    required this.area,
    required this.description,
    required this.riasecProfile,
    this.duration,
    required this.degreeType,
    required this.institutionType,
    required this.employmentField,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String area;
  final String description;
  final String riasecProfile;
  final String? duration;
  final DegreeType degreeType;
  final CareerInstitutionType institutionType;
  final String employmentField;
  final CareerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      id: json['id'] as int,
      name: json['name'] as String,
      area: json['area'] as String,
      description: json['description'] as String,
      riasecProfile: json['riasec_profile'] as String,
      duration: json['duration'] as String?,
      degreeType: DegreeType.fromApi(json['degree_type'] as String?),
      institutionType:
          CareerInstitutionType.fromApi(json['institution_type'] as String?),
      employmentField: json['employment_field'] as String,
      status: CareerStatus.fromApi(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'area': area,
      'description': description,
      'riasec_profile': riasecProfile.toUpperCase(),
      if (duration != null && duration!.isNotEmpty) 'duration': duration,
      'degree_type': degreeType.apiValue,
      'institution_type': institutionType.apiValue,
      'employment_field': employmentField,
      'status': status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'area': area,
      'description': description,
      'riasec_profile': riasecProfile.toUpperCase(),
      if (duration != null && duration!.isNotEmpty) 'duration': duration,
      'degree_type': degreeType.apiValue,
      'institution_type': institutionType.apiValue,
      'employment_field': employmentField,
      'status': status.apiValue,
    };
  }
}

class CareerMutationResult {
  const CareerMutationResult({
    required this.career,
    required this.message,
    required this.vectorSynced,
  });

  final Career career;
  final String message;
  final bool vectorSynced;

  factory CareerMutationResult.fromApiBody(Map<String, dynamic> body) {
    final data = Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
    final vectorSynced = data.remove('vector_synced') as bool? ?? false;
    return CareerMutationResult(
      career: Career.fromJson(data),
      message: body['message'] as String? ?? 'Operación realizada correctamente',
      vectorSynced: vectorSynced,
    );
  }
}

class PaginatedCareers {
  const PaginatedCareers({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<Career> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory PaginatedCareers.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedCareers(
      items: rawItems
          .map((item) => Career.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
