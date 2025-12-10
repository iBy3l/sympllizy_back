import 'base_exception.dart';

class NotFoundException extends BaseException {
  NotFoundException(super.message, {String? code, super.details}) : super(code: code ?? 'not_found', statusCode: 404);
}
