import 'package:sympllizy_back/core/core.dart';

import '../http/http_context_auth.dart';

Middleware requireRole(String role) {
  return (ctx, next) async {
    final auth = ctx.auth;

    if (auth == null) {
      throw UnauthorizedException('Autenticação necessária');
    }

    if (!auth.roles.contains(role)) {
      throw ForbiddenException('Permissão insuficiente');
    }

    await next();
  };
}
