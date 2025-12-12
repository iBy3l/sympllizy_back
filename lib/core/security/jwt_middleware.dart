import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sympllizy_back/core/core.dart';

Middleware jwtMiddleware(JwtService jwtService) {
  return (HttpContext ctx, Future<void> Function() next) async {
    final authHeader = ctx.header('authorization');

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw UnauthorizedException('Token não informado');
    }

    final token = authHeader.substring(7).trim();

    try {
      final jwt = jwtService.verifyAccessToken(token);

      // Injeta no contexto (disponível para toda a request)
      ctx.locals['user_id'] = jwtService.getUserId(jwt);
      ctx.locals['org_id'] = jwtService.getOrgId(jwt);
      ctx.locals['roles'] = jwtService.getRoles(jwt);

      await next();
    } on JWTExpiredException {
      throw UnauthorizedException('Token expirado');
    } on JWTException catch (e) {
      throw UnauthorizedException(e.message);
    }
  };
}
