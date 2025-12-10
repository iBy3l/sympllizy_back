import '../http/context.dart';

Future<void> loggingMiddleware(HttpContext ctx, Future<void> Function() next) async {
  print(
    '[REQ] ${ctx.method} ${ctx.path} '
    'ip=${ctx.ip} ua="${ctx.userAgent}"',
  );

  await next();

  final duration = DateTime.now().difference(ctx.startedAt);
  print(
    '[RES] ${ctx.method} ${ctx.path} '
    'status=${ctx.response.statusCode} '
    'duration=${duration.inMilliseconds}ms',
  );
}
