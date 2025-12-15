import 'package:sympllizy_back/core/core.dart';

Middleware requireRole(String role) {
  return (ctx, next) async {
    if (!ctx.isAuthenticated || !ctx.auth.roles.contains(role)) {
      throw ForbiddenException('Permissão insuficiente');
    }
    await next();
  };
}
