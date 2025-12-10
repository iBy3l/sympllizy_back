import 'base_exception.dart';

class AuthException extends BaseException {
  AuthException(super.message, {String? code, super.details}) : super(code: code ?? 'auth_error', statusCode: 401);
}
