import '../http/context.dart';

Future<void> orgContextMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final host = ctx.header('host');
  if (host == null || host.isEmpty) {
    return await next();
  }

  final parts = host.split('.');

  if (parts.length < 2) {
    return await next();
  }

  final sub = parts.first;

  if (sub == 'admin') {
    ctx.locals['context'] = 'platform';
  } else {
    ctx.locals['context'] = 'organization';
    ctx.locals['orgSlug'] = sub;
  }

  await next();
}
