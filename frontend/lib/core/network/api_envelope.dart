import '../errors/app_exception.dart';
import '../errors/failure_mapper.dart';

Map<String, dynamic> readSuccessData(Object? raw) {
  final envelope = readSuccessEnvelope(raw);
  final data = envelope['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw AppException(FailureMapper.unexpectedMessage);
}

Map<String, dynamic> readSuccessEnvelope(Object? raw) {
  final envelope = _asMap(raw);
  if (envelope['success'] != true) {
    throw AppException(FailureMapper.unexpectedMessage);
  }
  return envelope;
}

String readSuccessMessage(Object? raw, {String fallback = 'Operación realizada correctamente'}) {
  final envelope = readSuccessEnvelope(raw);
  final message = envelope['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  return fallback;
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
