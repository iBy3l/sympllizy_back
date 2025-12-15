import 'app_exception.dart';
import 'error_code.dart';

class ConflictException extends AppException {
  ConflictException(String message) : super(ErrorCode.conflict, message);
}
