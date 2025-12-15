import 'dart:io';

import 'package:sympllizy_back/core/http/response_utils.dart';
import 'package:sympllizy_back/core/logging/logging.dart';

import '../errors/erros.dart';
import '../http/api_response.dart';
import '../http/context.dart';

Future<void> errorMiddleware(Object error, StackTrace stack, HttpContext ctx) async {
  final logger = ctx.locals['logger'] as Logger?;

  // =========================
  // ERRO ESPERADO (AppException)
  // =========================
  if (error is AppException) {
    final status = statusFromError(error);

    await logger?.log(
      LogEntry(
        level: LogLevel.warn,
        type: errorCodeToString(error.code),
        message: error.message,
        context: error.details,
        userId: ctx.locals['userId'],
        orgId: ctx.locals['orgId'],
        method: ctx.method,
        path: ctx.path,
        ip: ctx.ip,
        userAgent: ctx.userAgent,
      ),
    );

    sendJson(ctx, status, ApiResponse.error(message: error.message, code: errorCodeToString(error.code), data: error.details));
    return;
  }

  // =========================
  // ERRO NÃO ESPERADO (BUG)
  // =========================
  await logger?.log(
    LogEntry(
      level: LogLevel.error,
      type: 'INTERNAL_ERROR',
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

  sendJson(ctx, HttpStatus.internalServerError, ApiResponse.error(message: 'Erro interno do servidor', code: errorCodeToString(ErrorCode.internalError)));
}

int statusFromError(AppException e) {
  switch (e.code) {
    case ErrorCode.validationError:
      return 422;
    case ErrorCode.unauthorized:
      return 401;
    case ErrorCode.forbidden:
      return 403;
    case ErrorCode.notFound:
      return 404;
    case ErrorCode.conflict:
      return 409;
    case ErrorCode.internalError:
      return 500;
  }
}
