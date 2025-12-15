import 'dart:io';

import 'package:sympllizy_back/core/core.dart';

import 'auth/auth.dart';

void registerModules({required Router router, required DatabaseConnection db, required JwtService jwtService, required PasswordHasher hasher, required Logger logger}) {
  // AUTH
  final authRoutes = authDependency(db: db, jwtService: jwtService, hasher: hasher, logger: logger);

  authRoutes.register(router);

  // FUTURO:
  // orgRoutes.register(router);
  // companyRoutes.register(router);
}

Router adminDependency({required JwtService jwtService}) {
  final router = Router();

  router.group('/admin', (r) {
    r.post('/stats', (ctx) async {
      sendJson(ctx, HttpStatus.ok, {'ok': true});
    });
  }, middlewares: [jwtMiddleware(jwtService), requireAuth(), requireRole('admin')]);

  return router;
}

MeRoutes meDependency({required JwtService jwtService}) {
  final router = Router();
  final controller = MeController();

  router.get('/me', chain([jwtMiddleware(jwtService), requireAuth()], controller.me));

  return MeRoutes(controller);
}

class MeController {
  Future<void> me(HttpContext ctx) async {
    final auth = ctx.auth;

    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Usuário autenticado', data: {'user_id': auth.userId, 'org_id': auth.orgId, 'roles': auth.roles}));
  }
}

class MeRoutes {
  final MeController controller;

  MeRoutes(this.controller);

  void register(Router router) {
    router.get(
      '/me',
      chain([
        requireAuth(), // 🔐 só entra se tiver JWT válido
      ], controller.me),
    );
  }
}
