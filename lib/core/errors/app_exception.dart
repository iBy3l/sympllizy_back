import 'package:sympllizy_back/core/errors/error_code.dart';

abstract class AppException implements Exception {
  final ErrorCode code;
  final String message;
  final Map<String, dynamic>? details;

  AppException(this.code, this.message, {this.details});

  @override
  String toString() => 'AppException(${errorCodeToString(code)}): $message';
}
