import 'base_exception.dart';

class ForbiddenException extends BaseException {
  ForbiddenException(super.message, {String? code, super.details}) : super(code: code ?? 'forbidden', statusCode: 403);
}
