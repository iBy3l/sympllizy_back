import 'dart:convert';
import 'dart:io';

import '../errors/base_exception.dart';
import '../errors/server_exception.dart';
import '../http/api_response.dart';
import '../http/context.dart';
import '../http/router.dart';

final ErrorHandler errorMiddleware = (Object error, StackTrace stack, HttpContext ctx) async {
  if (error is BaseException) {
    final body = ApiResponse.error(message: error.message, data: {'code': error.code, 'details': error.details});

    ctx.response
      ..statusCode = error.statusCode
      ..headers.contentType = ContentType.json
      ..write(body);
    await ctx.response.close();
    return;
  }

  // log simples (depois vamos jogar para o banco / logger próprio)
  print('[ERROR] $error');
  print(stack);

  final ex = ServerException('Erro interno do servidor');

  final body = ApiResponse.error(message: ex.message, data: {'code': ex.code});

  ctx.response
    ..statusCode = ex.statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await ctx.response.close();
};
