class SystemSetting {
  const SystemSetting({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String key;
  final String value;
  final String? description;
  final int? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      id: json['id'] as int,
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedBy: json['updated_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get label {
    switch (key) {
      case 'app_display_name':
        return 'Nombre de la aplicación';
      case 'ethical_disclaimer':
        return 'Mensaje ético';
      case 'max_recommendations_per_session':
        return 'Máximo de recomendaciones';
      case 'maintenance_mode':
        return 'Modo mantenimiento';
      default:
        return key;
    }
  }

  bool get isMultiline => key == 'ethical_disclaimer';

  bool get isBoolean => key == 'maintenance_mode';
}
