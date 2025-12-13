import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/modules/auth/auth_dependecy.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // ================= ERROR HANDLER =================
  router.setErrorHandler(errorMiddleware);

  // ================= DEPENDÊNCIAS =================
  final db = DB.instance;
  final dbLogger = DbLogger(db);
  final jwtService = JwtService.createFromEnv();
  const hasher = PasswordHasher();

  // ================= MIDDLEWARES GLOBAIS =================
  router.use(loggerContextMiddleware(dbLogger));
  router.use(requestLogger(dbLogger));
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);

  // ================= OPENAPI =================
  OpenApi.addOperation(
    method: 'get',
    path: '/health',
    operation: OpenApiOperation(
      summary: 'Health check da API',
      responses: {
        '200': {'description': 'API está rodando'},
      },
    ),
  );
  // ================= AUTH =================
  final authRoutes = authDependency(db: db, jwtService: jwtService, hasher: hasher, logger: dbLogger);
  authRoutes.register(router);

  // ================= PROTECTED ROUTES =================

  /// 🔐 /me → qualquer usuário autenticado
  router.get(
    '/me',
    chain([jwtMiddleware(jwtService), requireAuth()], (ctx) async {
      final auth = ctx.auth;

      sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Usuário autenticado', data: {'user_id': auth?.userId, 'org_id': auth?.orgId, 'roles': auth?.roles}));
    }),
  );

  /// 🔐 /admin → apenas admin
  router.group('/admin', (r) {
    r.post('/stats', (ctx) async {
      sendJson(ctx, HttpStatus.ok, {'ok': true});
    });
  }, middlewares: [jwtMiddleware(jwtService), requireAuth(), requireRole('admin')]);

  // ================= DOCS =================
  router.get('/openapi.json', (ctx) async {
    ctx.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(OpenApi.json());
    await ctx.response.close();
  });

  router.get('/docs', _swaggerHandler);
  router.get('/docs/:rest', _swaggerHandler);

  // ================= HEALTH =================
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
  });

  // ================= START =================
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}

// ================= SWAGGER HANDLER =================
Future<void> _swaggerHandler(HttpContext ctx) async {
  final shelfReq = await httpToShelfRequest(ctx.request);
  final shelfRes = await SwaggerHandler.handler(shelfReq);
  await sendShelfResponse(ctx.response, shelfRes);
}

class MeController {
  Future<void> me(HttpContext ctx) async {
    final auth = ctx.auth!;

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
