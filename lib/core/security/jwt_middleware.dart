import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/core/http/http_context_auth.dart';

Middleware jwtMiddleware(JwtService jwt) {
  return (ctx, next) async {
    final header = ctx.request.headers.value(HttpHeaders.authorizationHeader);

    if (header == null || !header.startsWith('Bearer ')) {
      await next();
      return;
    }

    final token = header.substring(7);

    try {
      final decoded = jwt.verifyAccessToken(token);

      final userId = jwt.getUserId(decoded);
      final orgId = jwt.getOrgId(decoded);
      final roles = jwt.getRoles(decoded);

      if (userId.isEmpty || orgId.isEmpty) {
        throw UnauthorizedException('Token inválido');
      }

      ctx.setAuth(AuthContext(userId: userId, orgId: orgId, roles: roles));
    } catch (e) {
      throw UnauthorizedException('Token inválido ou expirado');
    }

    await next();
  };
}
