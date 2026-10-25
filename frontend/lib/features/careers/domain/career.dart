class Career {
  const Career({
    required this.id,
    required this.name,
    required this.area,
    required this.description,
    required this.riasecProfile,
    required this.degreeType,
    required this.institutionType,
    required this.employmentField,
    required this.status,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String area;
  final String description;
  final String riasecProfile;
  final String? duration;
  final String degreeType;
  final String institutionType;
  final String employmentField;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  String get statusLabel => status == 'ACTIVE' ? 'Activa' : 'Inactiva';

  String get degreeTypeLabel => degreeTypeLabels[degreeType] ?? degreeType;

  String get institutionTypeLabel =>
      institutionTypeLabels[institutionType] ?? institutionType;

  factory Career.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final area = json['area'];
    final description = json['description'];
    final riasecProfile = json['riasec_profile'];
    final degreeType = json['degree_type'];
    final institutionType = json['institution_type'];
    final employmentField = json['employment_field'];
    final status = json['status'];
    if (id is! int ||
        name is! String ||
        area is! String ||
        description is! String ||
        riasecProfile is! String ||
        degreeType is! String ||
        institutionType is! String ||
        employmentField is! String ||
        status is! String) {
      throw const FormatException('Carrera incompleta');
    }
    return Career(
      id: id,
      name: name,
      area: area,
      description: description,
      riasecProfile: riasecProfile,
      duration: _optionalText(json['duration']),
      degreeType: degreeType,
      institutionType: institutionType,
      employmentField: employmentField,
      status: status,
      createdAt: _optionalText(json['created_at']),
      updatedAt: _optionalText(json['updated_at']),
    );
  }
}

class CareerPage {
  const CareerPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<Career> items;
  final int total;
  final int page;
  final int pages;
}

class CareerDraft {
  const CareerDraft({
    required this.name,
    required this.area,
    required this.description,
    required this.riasecProfile,
    required this.degreeType,
    required this.institutionType,
    required this.employmentField,
    this.duration,
    this.status = 'ACTIVE',
  });

  final String name;
  final String area;
  final String description;
  final String riasecProfile;
  final String? duration;
  final String degreeType;
  final String institutionType;
  final String employmentField;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'area': area,
      'description': description,
      'riasec_profile': riasecProfile.toUpperCase(),
      'degree_type': degreeType,
      'institution_type': institutionType,
      'employment_field': employmentField,
      'status': status,
      if (duration != null && duration!.trim().isNotEmpty)
        'duration': duration!.trim(),
    };
  }

  Map<String, dynamic> toUpdateJson() => toJson();
}

const degreeTypeLabels = <String, String>{
  'TECNOLOGICO': 'Tecnológico',
  'TERCER_NIVEL': 'Tercer nivel',
  'LICENCIATURA': 'Licenciatura',
  'INGENIERIA': 'Ingeniería',
  'OTRO': 'Otro',
};

const institutionTypeLabels = <String, String>{
  'PUBLICA': 'Pública',
  'PRIVADA': 'Privada',
  'AMBAS': 'Ambas',
};

final degreeTypeValues = degreeTypeLabels.keys.toList();

final institutionTypeValues = institutionTypeLabels.keys.toList();

String? _optionalText(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
