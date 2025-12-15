import 'app_exception.dart';
import 'error_code.dart';

class ForbiddenException extends AppException {
  ForbiddenException(String message) : super(ErrorCode.forbidden, message);
}
