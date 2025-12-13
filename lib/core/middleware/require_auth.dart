import 'package:sympllizy_back/core/http/http_context_auth.dart'; // 👈 ESSENCIAL

import '../core.dart';

Middleware requireAuth() {
  return (ctx, next) async {
    if (!ctx.isAuthenticated) {
      throw UnauthorizedException('Autenticação necessária');
    }
    await next();
  };
}
