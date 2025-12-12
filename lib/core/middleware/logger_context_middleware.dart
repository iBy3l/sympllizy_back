import '../core.dart';

Middleware loggerContextMiddleware(Logger logger) {
  return (ctx, next) async {
    ctx.locals['logger'] = logger;
    await next();
  };
}
