import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory AuthTokens.fromResponseData(Object? raw) {
    final envelope = _asMap(raw);
    if (envelope['success'] != true) {
      throw AppException(FailureMapper.unexpectedMessage);
    }
    final data = _asMap(envelope['data']);
    final accessToken = _requiredText(data['access_token']);
    final refreshToken = _requiredText(data['refresh_token']);
    final expiresIn = data['expires_in'];
    if (accessToken == null ||
        refreshToken == null ||
        expiresIn is! int ||
        expiresIn <= 0) {
      throw AppException(FailureMapper.unexpectedMessage);
    }
    final tokenType = data['token_type'];
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType is String && tokenType.isNotEmpty
          ? tokenType
          : 'bearer',
      expiresIn: expiresIn,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.institutionId,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final int? institutionId;

  factory UserProfile.fromResponseData(Object? raw) {
    final envelope = _asMap(raw);
    if (envelope['success'] != true) {
      throw AppException(FailureMapper.unexpectedMessage);
    }
    final data = _asMap(envelope['data']);
    final id = data['id'];
    final email = _requiredText(data['email']);
    final firstName = _requiredText(data['first_name']);
    final lastName = _requiredText(data['last_name']);
    final role = _requiredText(data['role']);
    final status = _requiredText(data['status']);
    if (id is! int ||
        email == null ||
        firstName == null ||
        lastName == null ||
        role == null ||
        status == null) {
      throw AppException(FailureMapper.unexpectedMessage);
    }
    final institutionId = data['institution_id'];
    return UserProfile(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      status: status,
      institutionId: institutionId is int ? institutionId : null,
    );
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  throw AppException(FailureMapper.unexpectedMessage);
}

String? _requiredText(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
