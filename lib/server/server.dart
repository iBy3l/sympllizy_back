import 'dart:io';

import '../core/core.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // error handler
  router.setErrorHandler(errorMiddleware);

  // middlewares
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);
  // router.use(authMiddleware); // depois, quando quiser global

  // rota básica de health-check
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
  });

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}
