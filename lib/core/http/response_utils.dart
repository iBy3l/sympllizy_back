import 'dart:convert';
import 'dart:io';

import 'context.dart';

void sendJson(HttpContext ctx, int statusCode, Map<String, dynamic> body) {
  ctx.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
}
