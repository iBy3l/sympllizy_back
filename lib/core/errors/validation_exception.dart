import 'app_exception.dart';
import 'error_code.dart';

class ValidationException extends AppException {
  ValidationException(String message, {Map<String, dynamic>? details}) : super(ErrorCode.validationError, message, details: details);
}
