import 'dart:convert';
import 'dart:io';

import '../errors/erros.dart';

Future<Map<String, dynamic>> readJson(HttpRequest request) async {
  try {
    final content = await utf8.decoder.bind(request).join();

    if (content.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw ValidationException('Payload inválido');
    }

    return decoded;
  } on FormatException {
    throw ValidationException('JSON inválido');
  }
}
