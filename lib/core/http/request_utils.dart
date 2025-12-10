import 'dart:convert';

import '../errors/validation_exception.dart';
import 'context.dart';

Future<Map<String, dynamic>> readJsonBody(HttpContext ctx) async {
  final body = await utf8.decoder.bind(ctx.request).join();

  if (body.trim().isEmpty) return {};

  final decoded = jsonDecode(body);

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  throw ValidationException('JSON inválido. Esperado objeto.');
}
