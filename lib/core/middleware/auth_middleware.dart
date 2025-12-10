import '../errors/auth_exception.dart';
import '../http/context.dart';

Future<void> authMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final header = ctx.header('authorization');

  if (header == null || !header.startsWith('Bearer ')) {
    throw AuthException('Token não informado');
  }

  final token = header.substring(7).trim();
  ctx.locals['rawToken'] = token;

  await next();
}
