iby3l@192 sympllizy_back % tree                    
.
├── analysis_options.yaml
├── app.md
├── bin
│   ├── server.dart
│   └── test_jwt.dart
├── CHANGELOG.md
├── Dockerfile
├── lib
│   ├── core
│   │   ├── config
│   │   │   ├── app_config.dart
│   │   │   ├── config.dart
│   │   │   └── environment.dart
│   │   ├── core.dart
│   │   ├── database
│   │   │   ├── database_connection.dart
│   │   │   ├── db.dart
│   │   │   └── postgres_connection.dart
│   │   ├── env
│   │   │   └── env.dart
│   │   ├── errors
│   │   │   ├── auth_exception.dart
│   │   │   ├── base_exception.dart
│   │   │   ├── erros.dart
│   │   │   ├── forbidden_exception.dart
│   │   │   ├── not_found_exception.dart
│   │   │   ├── server_exception.dart
│   │   │   └── validation_exception.dart
│   │   ├── http
│   │   │   ├── api_response.dart
│   │   │   ├── context.dart
│   │   │   ├── http_to_shelf.dart
│   │   │   ├── http.dart
│   │   │   ├── request_utils.dart
│   │   │   ├── response_utils.dart
│   │   │   ├── router.dart
│   │   │   └── shelf_to_http.dart
│   │   ├── middleware
│   │   │   ├── auth_middleware.dart
│   │   │   ├── cors_middleware.dart
│   │   │   ├── error_middleware.dart
│   │   │   ├── logging_middleware.dart
│   │   │   ├── middleware.dart
│   │   │   └── org_context_middleware.dart
│   │   ├── openapi
│   │   │   ├── modules
│   │   │   │   └── modules.dart
│   │   │   ├── openapi.dart
│   │   │   └── openapi.yaml
│   │   ├── security
│   │   │   ├── jwt_service.dart
│   │   │   ├── password_hash.dart
│   │   │   ├── security.dart
│   │   │   └── token_pair.dart
│   │   └── swagger
│   │       ├── openapi_spec.dart
│   │       └── swagger_handler.dart
│   └── server
│       └── server.dart
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── test
    └── server_test.dart


├── config
app_config.dart:
import 'package:sympllizy_back/core/config/environment.dart';

import '../env/env.dart';

class AppConfig {
  static late final Environment environment;
  static late final bool isDebug;
  static late final bool enableQueryLogs;
  static late final String databaseUrl;

  static void load() {
    environment = Environment.fromString(Env.get('APP_ENV', fallback: 'dev'));

    isDebug = environment == Environment.dev;
    enableQueryLogs = environment != Environment.prod;

    databaseUrl = Env.get('DATABASE_URL');

    print('[CONFIG] Environment: $environment');
    print('[CONFIG] Debug: $isDebug');
  }

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;
}


│── environment.dart:
enum Environment {
  dev,
  staging,
  prod;

  static Environment fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'dev':
      case 'development':
        return Environment.dev;

      case 'staging':
      case 'stage':
        return Environment.staging;

      case 'prod':
      case 'production':
        return Environment.prod;

      default:
        return Environment.dev;
    }
  }
}


database_connection.dart: 
abstract class DatabaseConnection {
  Future<void> connect();

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic> params]);

  Future<int> execute(String sql, [List<dynamic> params]);

  Future<T> transaction<T>(Future<T> Function() action);
}

db.dart:

import 'package:sympllizy_back/core/database/database_connection.dart';

class DB {
  static late final DatabaseConnection _instance;

  DB._();

  static void init(DatabaseConnection connection) {
    _instance = connection;
  }

  static DatabaseConnection get instance => _instance;
}


postgres_connection.dart:
import 'package:postgres/postgres.dart';
import 'package:sympllizy_back/core/database/database_connection.dart';

class PostgresConnection extends DatabaseConnection {
  final String url;
  late final Endpoint _endpoint;

  Connection? _conn;

  PostgresConnection(this.url) {
    final uri = Uri.parse(url);

    _endpoint = Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '',
    );
  }

  @override
  Future<void> connect() async {
    _conn = await Connection.open(
      _endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.disable, // LOCAL => sem SSL
      ),
    );

    print('[DB] Conectado com sucesso!');
  }

  Connection get raw => _conn!;

  // --------------------------
  // QUERY
  // --------------------------
  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    if (_conn == null) throw Exception('DB não conectado');

    final result = await _conn!.execute(sql, parameters: params ?? const []);

    return result.map((row) => row.toColumnMap()).toList();
  }

  // --------------------------
  // EXECUTE (INSERT/UPDATE/DELETE)
  // --------------------------
  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    if (_conn == null) throw Exception('DB não conectado');

    final result = await _conn!.execute(sql, parameters: params ?? const []);

    return result.affectedRows;
  }

  // --------------------------
  // TRANSACTION
  // --------------------------
  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    if (_conn == null) throw Exception('DB não conectado');

    return await _conn!.runTx((session) async {
      try {
        final value = await action();
        return value;
      } catch (e) {
        await session.rollback();
        rethrow;
      }
    });
  }
}

 env.dart:
 DATABASE_URL=postgres://symp_user:minhasenha@localhost:5432/sympllizy
PORT=8080

JWT_SECRET=minha_chave_super_secreta
JWT_ISSUER=sympllizy-backend


auth_exception.dart:
import 'base_exception.dart';

class AuthException extends BaseException {
  AuthException(super.message, {String? code, super.details}) : super(code: code ?? 'auth_error', statusCode: 401);
}

base_exception.dart:
class BaseException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  BaseException(this.message, {this.statusCode = 400, this.code, this.details});

  @override
  String toString() => 'BaseException($statusCode, $code, $message)';
}

forbidden_exception.dart
class ForbiddenException extends BaseException {
  ForbiddenException(super.message, {String? code, super.details}) : super(code: code ?? 'forbidden', statusCode: 403);
}

not_found_exception.dart:
import 'base_exception.dart';

class NotFoundException extends BaseException {
  NotFoundException(super.message, {String? code, super.details}) : super(code: code ?? 'not_found', statusCode: 404);
}

server_exception.dart:
import 'base_exception.dart';

class ServerException extends BaseException {
  ServerException(super.message, {String? code, super.details}) : super(code: code ?? 'server_error', statusCode: 500);
}

validation_exception.dart:
import 'base_exception.dart';

class ValidationException extends BaseException {
  ValidationException(super.message, {super.details, String? code}) : super(code: code ?? 'validation_error', statusCode: 400);
}
├── http
api_response.dart:
class ApiResponse {
  static Map<String, dynamic> success({String message = 'OK', dynamic data}) {
    return {'success': true, 'message': message, 'data': data};
  }

  static Map<String, dynamic> error({String message = 'Erro', dynamic data}) {
    return {'success': false, 'message': message, 'data': data};
  }
}

http_to_shelf.dart:
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

shelf_to_http.dart:
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


context.dart:
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

  String? header(String name) => request.headers.value(name);

  String get ip {
    final forwarded = header('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
    return request.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  String get userAgent => header('user-agent') ?? '';
}

request_utils.dart:
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

response_utils.dart:
import 'dart:convert';
import 'dart:io';

import 'context.dart';

void sendJson(HttpContext ctx, int statusCode, Map<String, dynamic> body) {
  ctx.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
}

router.dart:
import 'dart:io';

import 'context.dart';

typedef Handler = Future<void> Function(HttpContext ctx);
typedef Middleware = Future<void> Function(HttpContext ctx, Future<void> Function() next);
typedef ErrorHandler = Future<void> Function(Object error, StackTrace stack, HttpContext ctx);

class _RouteEntry {
  final String method;
  final String path;
  final List<String> segments;
  final Handler handler;

  _RouteEntry(this.method, this.path, this.segments, this.handler);
}

class Router {
  final List<Middleware> _middlewares = [];
  final List<_RouteEntry> _routes = [];
  ErrorHandler? _errorHandler;

  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  void setErrorHandler(ErrorHandler handler) {
    _errorHandler = handler;
  }

  void get(String path, Handler handler) => _add('GET', path, handler);
  void post(String path, Handler handler) => _add('POST', path, handler);
  void put(String path, Handler handler) => _add('PUT', path, handler);
  void delete(String path, Handler handler) => _add('DELETE', path, handler);
  void patch(String path, Handler handler) => _add('PATCH', path, handler);
  void options(String path, Handler handler) => _add('OPTIONS', path, handler);

  void _add(String method, String path, Handler handler) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    final segments = cleaned.isEmpty ? <String>[] : cleaned.split('/');
    _routes.add(_RouteEntry(method.toUpperCase(), path, segments, handler));
  }

  Future<void> handle(HttpRequest request) async {
    final ctx = HttpContext(request);

    try {
      final route = _matchRoute(ctx.method, ctx.path, ctx.params);

      if (route == null) {
        ctx.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found');
        await ctx.response.close();
        return;
      }

      var i = -1;
      Future<void> run() async {
        i++;
        if (i < _middlewares.length) {
          await _middlewares[i](ctx, run);
        } else {
          await route.handler(ctx);
        }
      }

      await run();
    } catch (e, stack) {
      if (_errorHandler != null) {
        await _errorHandler!(e, stack, ctx);
      } else {
        ctx.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal Server Error');
        await ctx.response.close();
      }
    }
  }

  _RouteEntry? _matchRoute(String method, String path, Map<String, String> params) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    final pathSegments = cleaned.isEmpty ? <String>[] : cleaned.split('/');

    for (final r in _routes) {
      if (r.method != method.toUpperCase()) continue;
      if (r.segments.length != pathSegments.length) continue;

      params.clear();
      var ok = true;

      for (var i = 0; i < r.segments.length; i++) {
        final seg = r.segments[i];
        final val = pathSegments[i];

        if (seg.startsWith(':')) {
          params[seg.substring(1)] = val;
        } else if (seg != val) {
          ok = false;
          break;
        }
      }

      if (ok) return r;
    }

    return null;
  }
}

│── middleware

auth_middleware.dart:
import '../errors/auth_exception.dart';
import '../http/context.dart';

Future<void> authMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final header = ctx.header('authorization');

  if (header == null || !header.startsWith('Bearer ')) {
    throw AuthException('Token não informado');
  }

  final token = header.substring(7).trim();
  ctx.locals['rawToken'] = token;

  await next();
}

cors_middleware.dart:
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

error_middleware.dart:
import 'dart:io';

import '../errors/base_exception.dart';
import '../errors/server_exception.dart';
import '../http/api_response.dart';
import '../http/context.dart';
import '../http/router.dart';

final ErrorHandler errorMiddleware = (Object error, StackTrace stack, HttpContext ctx) async {
  if (error is BaseException) {
    final body = ApiResponse.error(message: error.message, data: {'code': error.code, 'details': error.details});

    ctx.response
      ..statusCode = error.statusCode
      ..headers.contentType = ContentType.json
      ..write(body);
    await ctx.response.close();
    return;
  }

  // log simples (depois vamos jogar para o banco / logger próprio)
  print('[ERROR] $error');
  print(stack);

  final ex = ServerException('Erro interno do servidor');

  final body = ApiResponse.error(message: ex.message, data: {'code': ex.code});

  ctx.response
    ..statusCode = ex.statusCode
    ..headers.contentType = ContentType.json
    ..write(body);
  await ctx.response.close();
};

logging_middleware.dart:
import '../http/context.dart';

Future<void> loggingMiddleware(HttpContext ctx, Future<void> Function() next) async {
  print(
    '[REQ] ${ctx.method} ${ctx.path} '
    'ip=${ctx.ip} ua="${ctx.userAgent}"',
  );

  await next();

  final duration = DateTime.now().difference(ctx.startedAt);
  print(
    '[RES] ${ctx.method} ${ctx.path} '
    'status=${ctx.response.statusCode} '
    'duration=${duration.inMilliseconds}ms',
  );
}


org_context_middleware.dart:
import '../http/context.dart';

Future<void> orgContextMiddleware(HttpContext ctx, Future<void> Function() next) async {
  final host = ctx.header('host');
  if (host == null || host.isEmpty) {
    return await next();
  }

  final parts = host.split('.');

  if (parts.length < 2) {
    return await next();
  }

  final sub = parts.first;

  if (sub == 'admin') {
    ctx.locals['context'] = 'platform';
  } else {
    ctx.locals['context'] = 'organization';
    ctx.locals['orgSlug'] = sub;
  }

  await next();
}
lib/server/server.dart:
import 'dart:io';

import '../core/core.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // error handler
  router.setErrorHandler(errorMiddleware);

  // middlewares
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);
  // router.use(authMiddleware); // depois, quando quiser global

  // rota básica de health-check
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
  });

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}
openapi/openapi.yaml
openapi: 3.1.0
info:
  title: Sympllizy API
  version: "1.0.0"

paths:
  /ping:
    get:
      summary: Check API health
      responses:
        '200':
          description: OK


swagger/openapi_spec.dart:
class OpenApiSpec {
  static String get spec => '''
{
  "openapi": "3.1.0",
  "info": {
    "title": "Sympllizy API",
    "version": "1.0.0"
  },
  "paths": {
    "/ping": {
      "get": {
        "summary": "API health check",
        "responses": {
          "200": {
            "description": "API is up"
          }
        }
      }
    }
  }
}
''';
}
swagger/swagger_handler.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import 'openapi_spec.dart';

class SwaggerHandler {
  static Handler get handler => SwaggerUI(
    OpenApiSpec.spec, // <- aqui passa o schema diretamente
    title: 'Sympllizy API Docs',
    specType: SpecType.json,
    docExpansion: DocExpansion.list,
    deepLink: true,
    persistAuthorization: true,
  ).call;
}


pubspec.yaml
name: sympllizy_back
description: A server app using the shelf package and Docker.
version: 1.0.0
# repository: https://github.com/my_org/my_repo

environment:
  sdk: ^3.9.2

dependencies:
  bcrypt: ^1.1.3
  crypto: ^3.0.7
  dart_jsonwebtoken: ^3.3.1
  dotenv: ^4.2.0
  postgres: ^3.5.9
  shelf: ^1.4.2
  shelf_router: ^1.1.2
  shelf_swagger_ui: ^2.0.0

dev_dependencies:
  http: ^1.2.2
  lints: ^6.0.0
  test: ^1.25.6
