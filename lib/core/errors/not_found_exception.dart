import 'app_exception.dart';
import 'error_code.dart';

class NotFoundException extends AppException {
  NotFoundException(String message) : super(ErrorCode.notFound, message);
}
