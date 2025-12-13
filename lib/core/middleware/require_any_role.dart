import '../core.dart';

Middleware requireAnyRole(List<String> roles) {
  return (ctx, next) async {
    if (!ctx.isAuthenticated) {
      throw UnauthorizedException('Autenticação necessária');
    }

    final allowed = ctx.auth?.roles.any(roles.contains) ?? false;

    if (!allowed) {
      throw ForbiddenException('Permissão insuficiente');
    }

    await next();
  };
}
