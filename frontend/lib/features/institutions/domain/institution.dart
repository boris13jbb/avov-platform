class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.code,
    required this.province,
    required this.city,
    required this.status,
    this.address,
    this.phone,
    this.email,
    this.createdAt,
  });

  final int id;
  final String name;
  final String code;
  final String province;
  final String city;
  final String status;
  final String? address;
  final String? phone;
  final String? email;
  final String? createdAt;

  String get statusLabel => status == 'ACTIVE' ? 'Activa' : 'Inactiva';

  factory Institution.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final code = json['code'];
    final province = json['province'];
    final city = json['city'];
    final status = json['status'];
    if (id is! int ||
        name is! String ||
        code is! String ||
        province is! String ||
        city is! String ||
        status is! String) {
      throw const FormatException('Institución incompleta');
    }
    return Institution(
      id: id,
      name: name,
      code: code,
      province: province,
      city: city,
      status: status,
      address: _text(json['address']),
      phone: _text(json['phone']),
      email: _text(json['email']),
      createdAt: _text(json['created_at']),
    );
  }
}

class InstitutionPage {
  const InstitutionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<Institution> items;
  final int total;
  final int page;
  final int pages;
}

class InstitutionDraft {
  const InstitutionDraft({
    required this.name,
    required this.code,
    required this.province,
    required this.city,
    this.address,
    this.phone,
    this.email,
    this.status = 'ACTIVE',
  });

  final String name;
  final String code;
  final String province;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'province': province,
      'city': city,
      'status': status,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
    };
  }

  /// El alta omite opcionales vacíos. La edición envía null para borrarlos.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'province': province,
      'city': city,
      'status': status,
      'address': _emptyToNull(address),
      'phone': _emptyToNull(phone),
      'email': _emptyToNull(email),
    };
  }
}

String? _emptyToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

String? _text(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
