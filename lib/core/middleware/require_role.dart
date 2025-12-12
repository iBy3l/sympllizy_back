import 'package:sympllizy_back/core/core.dart';

Middleware requireRole(List<String> allowedRoles) {
  return (HttpContext ctx, Future<void> Function() next) async {
    final roles = ctx.locals['roles'];

    if (roles == null || roles is! List<String>) {
      throw ForbiddenException('Permissões não encontradas');
    }

    final hasPermission = roles.any(allowedRoles.contains);

    if (!hasPermission) {
      throw ForbiddenException('Acesso negado', details: {'required_roles': allowedRoles, 'user_roles': roles});
    }

    await next();
  };
}
