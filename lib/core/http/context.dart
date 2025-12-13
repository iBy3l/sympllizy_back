import 'dart:convert';
import 'dart:io';

class HttpContext {
  final HttpRequest request;
  final DateTime startedAt;
  final Map<String, dynamic> locals = {};
  final Map<String, String> params = {};

  HttpContext(this.request) : startedAt = DateTime.now();

  HttpResponse get response => request.response;

  String get method => request.method;
  Uri get uri => request.uri;
  String get path => request.uri.path;
  Map<String, String> get query => request.uri.queryParameters;
  final Map<String, dynamic> items = {};

  String? header(String name) => request.headers.value(name);

  String get ip {
    final forwarded = header('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
    return request.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  String get userAgent => header('user-agent') ?? '';

  Future<dynamic> bodyAsJson() async {
    final content = await utf8.decoder.bind(request).join();
    return content.isNotEmpty ? jsonDecode(content) : {};
  }
}
