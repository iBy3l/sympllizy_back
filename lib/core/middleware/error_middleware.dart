import 'dart:io';

import 'package:sympllizy_back/core/http/response_utils.dart';
import 'package:sympllizy_back/core/logging/logging.dart';

import '../http/api_response.dart';
import '../http/context.dart';

Future<void> errorMiddleware(Object error, StackTrace stack, HttpContext ctx) async {
  final logger = ctx.locals['logger'] as Logger?;

  await logger?.log(
    LogEntry(
      level: LogLevel.error,
      type: 'error',
      message: error.toString(),
      context: {'stack': stack.toString()},
      userId: ctx.locals['userId'],
      orgId: ctx.locals['orgId'],
      method: ctx.method,
      path: ctx.path,
      ip: ctx.ip,
      userAgent: ctx.userAgent,
    ),
  );

  sendJson(ctx, HttpStatus.internalServerError, ApiResponse.error(message: 'Erro interno'));
}
