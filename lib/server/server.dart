import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/core/swagger/swagger_handler.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // error handler
  router.setErrorHandler(errorMiddleware);

  // middlewares
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);
  // router.use(authMiddleware); // depois, quando quiser global

  // registro da doc (pode ficar logo após o router.get)
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

  router.get('/openapi.json', (ctx) async {
    final json = OpenApi.json();

    ctx.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(json);

    await ctx.response.close();
  });
  router.get('/docs', (ctx) async {
    final shelfReq = await httpToShelfRequest(ctx.request);
    final shelfRes = await SwaggerHandler.handler(shelfReq);
    await sendShelfResponse(ctx.response, shelfRes);
  });

  router.get('/docs/:rest', (ctx) async {
    final shelfReq = await httpToShelfRequest(ctx.request);
    final shelfRes = await SwaggerHandler.handler(shelfReq);
    await sendShelfResponse(ctx.response, shelfRes);
  });

  // server.dart
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
    return; // <<< ESSENCIAL
  });

  // registro da doc (pode ficar logo após o router.get)
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

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}
