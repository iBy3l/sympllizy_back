import 'base_exception.dart';

class UnauthorizedException extends BaseException {
  UnauthorizedException(super.message, {String? code, super.details}) : super(code: code ?? 'unauthorized', statusCode: 401);
}
