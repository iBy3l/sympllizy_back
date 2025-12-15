import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/modules/module_dependecy.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // ================= ERROR HANDLER =================
  router.setErrorHandler(errorMiddleware);

  // ================= DEPENDÊNCIAS =================
  final db = DB.instance;
  final logger = DbLogger(db);
  final jwtService = JwtService.createFromEnv();
  const hasher = PasswordHasher();

  // ================= MIDDLEWARES GLOBAIS =================
  router.use(loggerContextMiddleware(logger));
  router.use(requestLogger(logger));
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);

  // ================= MODULES =================
  registerModules(router: router, db: db, jwtService: jwtService, hasher: hasher, logger: logger);

  // ================= DOCS =================
  router.get('/openapi.json', openApiHandler);
  router.get('/docs', swaggerHandler);
  router.get('/docs/:rest', swaggerHandler);

  // ================= HEALTH =================
  router.get('/health', healthHandler);

  // ================= START =================
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}

/// ================= OPENAPI JSON =================
Future<void> openApiHandler(HttpContext ctx) async {
  ctx.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(OpenApi.json());

  await ctx.response.close();
}

/// ================= SWAGGER UI =================
Future<void> swaggerHandler(HttpContext ctx) async {
  final shelfReq = await httpToShelfRequest(ctx.request);
  final shelfRes = await SwaggerHandler.handler(shelfReq);
  await sendShelfResponse(ctx.response, shelfRes);
}

/// ================= HEALTH =================
Future<void> healthHandler(HttpContext ctx) async {
  sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
}
