import 'dart:io';

import '../http/context.dart';

Future<void> corsMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final res = ctx.response;

  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,PATCH,OPTIONS');
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (ctx.method == 'OPTIONS') {
    res.statusCode = HttpStatus.noContent;
    await res.close();
    return;
  }

  await next();
}
