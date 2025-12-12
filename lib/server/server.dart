import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/core/swagger/swagger_handler.dart';
import 'package:sympllizy_back/modules/auth/auth_dependecy.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // ============ ERROR HANDLER ============
  router.setErrorHandler(errorMiddleware);

  // ============ DEPENDÊNCIAS ============
  final db = DB.instance;
  final dbLogger = DbLogger(db);
  final jwtService = JwtService.createFromEnv();
  const hasher = PasswordHasher();

  // ============ MIDDLEWARES GLOBAIS (ORDEM IMPORTA) ============
  router.use(loggerContextMiddleware(dbLogger)); // 1️⃣ contexto
  router.use(requestLogger(dbLogger)); // 2️⃣ log de acesso
  router.use(loggingMiddleware); // 3️⃣ console (dev)
  router.use(corsMiddleware); // 4️⃣ CORS
  router.use(orgContextMiddleware); // 5️⃣ org context

  // ============ OPENAPI ============
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

  // ============ ROTAS DE NEGÓCIO ============
  final authRoutes = authDependency(db: db, jwtService: jwtService, hasher: hasher);
  authRoutes.register(router);

  // ============ DOCS ============
  router.get('/openapi.json', (ctx) async {
    ctx.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(OpenApi.json());
    await ctx.response.close();
  });

  router.get('/docs', _swaggerHandler);
  router.get('/docs/:rest', _swaggerHandler);

  // ============ HEALTH ============
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
  });

  // ============ START ============
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}

// ================== SWAGGER HANDLER ==================
Future<void> _swaggerHandler(HttpContext ctx) async {
  final shelfReq = await httpToShelfRequest(ctx.request);
  final shelfRes = await SwaggerHandler.handler(shelfReq);
  await sendShelfResponse(ctx.response, shelfRes);
}
