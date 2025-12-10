import 'dart:io';

import 'package:shelf/shelf.dart';

Future<void> sendShelfResponse(HttpResponse res, Response shelfRes) async {
  shelfRes.headersAll.forEach((name, values) {
    for (final val in values) {
      res.headers.add(name, val);
    }
  });

  res.statusCode = shelfRes.statusCode;

  final body = await shelfRes.readAsString();
  res.write(body);

  await res.close();
}
