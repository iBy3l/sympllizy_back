import 'package:sympllizy_back/core/core.dart';

Middleware jwtMiddleware(JwtService jwt) {
  return (ctx, next) async {
    final authHeader = ctx.header('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return await next(); // deixa passar, requireAuth decide
    }

    final token = authHeader.substring(7);

    final decoded = jwt.verifyAccessToken(token);

    ctx.setAuth(AuthContext(userId: jwt.getUserId(decoded), orgId: jwt.getOrgId(decoded), roles: jwt.getRoles(decoded)));

    await next();
  };
}
