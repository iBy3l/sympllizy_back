import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';

Future<Request> httpToShelfRequest(HttpRequest req) async {
  final bodyBytes = await req.fold<List<int>>(<int>[], (buffer, data) => buffer..addAll(data));

  final headers = <String, String>{};
  req.headers.forEach((k, v) {
    if (v.isNotEmpty) headers[k] = v.join(',');
  });

  return Request(req.method, req.requestedUri, protocolVersion: req.protocolVersion, headers: headers, body: Stream.fromIterable([bodyBytes]));
}
