enum InstitutionStatus {
  active('ACTIVE'),
  inactive('INACTIVE');

  const InstitutionStatus(this.apiValue);

  final String apiValue;

  static InstitutionStatus fromApi(String? value) {
    for (final status in InstitutionStatus.values) {
      if (status.apiValue == value) return status;
    }
    return InstitutionStatus.active;
  }

  String get label {
    switch (this) {
      case InstitutionStatus.active:
        return 'Activa';
      case InstitutionStatus.inactive:
        return 'Inactiva';
    }
  }
}

class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.code,
    required this.province,
    required this.city,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String code;
  final String province;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final InstitutionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String?,
      status: InstitutionStatus.fromApi(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'code': code,
      'province': province,
      'city': city,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logo_url': logoUrl,
      'status': status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'code': code,
      'province': province,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'status': status.apiValue,
    };
  }

  /// Campos editables por el administrador institucional (sin código, estado ni logo).
  Map<String, dynamic> toInstitutionAdminUpdateJson() {
    return {
      'name': name,
      'province': province,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}

class PaginatedInstitutions {
  const PaginatedInstitutions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<Institution> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory PaginatedInstitutions.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedInstitutions(
      items: rawItems
          .map((item) => Institution.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
