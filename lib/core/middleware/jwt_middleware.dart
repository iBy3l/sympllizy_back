import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sympllizy_back/core/core.dart';

Middleware jwtMiddleware(JwtService jwt) {
  return (HttpContext ctx, Future<void> Function() next) async {
    final authHeader = ctx.header('authorization');

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw UnauthorizedException('Token não informado');
    }

    final token = authHeader.substring(7).trim();

    try {
      final jwtToken = jwt.verifyAccessToken(token);

      // popula contexto
      ctx.locals['user_id'] = jwt.getUserId(jwtToken);
      ctx.locals['org_id'] = jwt.getOrgId(jwtToken);
      ctx.locals['roles'] = jwt.getRoles(jwtToken);

      await next();
    } on JWTExpiredException {
      throw UnauthorizedException('Token expirado');
    } on JWTException catch (e) {
      throw UnauthorizedException(e.message);
    }
  };
}
