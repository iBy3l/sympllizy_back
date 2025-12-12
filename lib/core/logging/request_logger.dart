import 'package:sympllizy_back/core/core.dart';

Middleware requestLogger(Logger logger) {
  return (HttpContext ctx, next) async {
    final start = DateTime.now();

    try {
      await next();

      final duration = DateTime.now().difference(start).inMilliseconds;

      await logger.log(
        LogEntry(
          level: LogLevel.info,
          type: 'access',
          message: 'HTTP ${ctx.method} ${ctx.path}',
          method: ctx.method,
          path: ctx.path,
          statusCode: ctx.response.statusCode,
          userId: ctx.locals['userId'],
          orgId: ctx.locals['orgId'],
          ip: ctx.ip,
          userAgent: ctx.userAgent,
          context: {'duration_ms': duration},
        ),
      );
    } catch (e) {
      rethrow;
    }
  };
}
