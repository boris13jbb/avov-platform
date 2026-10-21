import '../errors/app_exception.dart';
import '../errors/failure_mapper.dart';

Map<String, dynamic> readSuccessData(Object? raw) {
  final envelope = _asMap(raw);
  if (envelope['success'] != true) {
    throw AppException(FailureMapper.unexpectedMessage);
  }
  return _asMap(envelope['data']);
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
