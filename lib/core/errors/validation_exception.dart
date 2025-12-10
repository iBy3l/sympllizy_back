import 'base_exception.dart';

class ValidationException extends BaseException {
  ValidationException(super.message, {super.details, String? code}) : super(code: code ?? 'validation_error', statusCode: 400);
}
