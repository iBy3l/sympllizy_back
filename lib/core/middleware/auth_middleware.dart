import '../errors/unauthorized_exception.dart';
import '../http/context.dart';

Future<void> authMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final header = ctx.header('authorization');

  if (header == null || !header.startsWith('Bearer ')) {
    throw UnauthorizedException('Token não informado');
  }

  final token = header.substring(7).trim();

  if (token.isEmpty) {
    throw UnauthorizedException('Token inválido');
  }

  ctx.locals['rawToken'] = token;

  await next();
}
