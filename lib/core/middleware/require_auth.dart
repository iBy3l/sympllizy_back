import '../core.dart';

Middleware requireAuth() {
  return (ctx, next) async {
    if (!ctx.isAuthenticated) {
      throw UnauthorizedException('Autenticação necessária');
    }
    await next();
  };
}
