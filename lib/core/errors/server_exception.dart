import 'base_exception.dart';

class ServerException extends BaseException {
  ServerException(super.message, {String? code, super.details}) : super(code: code ?? 'server_error', statusCode: 500);
}
