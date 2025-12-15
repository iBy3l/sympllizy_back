import 'package:sympllizy_back/core/errors/app_exception.dart';
import 'package:sympllizy_back/core/errors/error_code.dart';

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(ErrorCode.unauthorized, message);
}
