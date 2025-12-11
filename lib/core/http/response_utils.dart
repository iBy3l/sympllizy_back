import 'dart:convert';
import 'dart:io';

import 'context.dart';

Future<void> sendJson(HttpContext ctx, int status, Map<String, dynamic> body) async {
  ctx.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await ctx.response.close();
}
