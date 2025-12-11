import 'dart:io';

import 'package:sympllizy_back/core/core.dart';

void registerTestRoutes(Router router) {
  router.get('/test/db', (ctx) async {
    try {
      final result = await DB.instance.query("SELECT NOW() as time;");
      return sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: "DB OK", data: result.first));
    } catch (e) {
      return sendJson(ctx, HttpStatus.internalServerError, ApiResponse.error(message: e.toString()));
    }
  });
}
