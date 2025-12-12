.
├── analysis_options.yaml
├── app.md
├── arq.md
├── bin
│   ├── server.dart
│   ├── test_db.dart
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
│   │   │   ├── database.dart
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
│   │   │   ├── unauthorized_exception.dart
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
│   │   ├── logging
│   │   │   ├── audit_logger.dart
│   │   │   ├── db_logger.dart
│   │   │   ├── log_entry.dart
│   │   │   ├── log_level.dart
│   │   │   ├── logger.dart
│   │   │   ├── logging.dart
│   │   │   └── request_logger.dart
│   │   ├── middleware
│   │   │   ├── auth_middleware.dart
│   │   │   ├── cors_middleware.dart
│   │   │   ├── error_middleware.dart
│   │   │   ├── jwt_middleware.dart
│   │   │   ├── logging_middleware.dart
│   │   │   ├── middleware.dart
│   │   │   ├── org_context_middleware.dart
│   │   │   └── require_role.dart
│   │   ├── openapi
│   │   │   ├── openapi.dart
│   │   │   └── openapi.yaml
│   │   ├── routes
│   │   │   ├── routes.dart
│   │   │   └── test_route.dart
│   │   ├── security
│   │   │   ├── jwt_service.dart
│   │   │   ├── password_hash.dart
│   │   │   ├── security.dart
│   │   │   └── token_pair.dart
│   │   └── swagger
│   │       ├── openapi_spec.dart
│   │       └── swagger_handler.dart
│   ├── modules
│   │   ├── auth
│   │   │   ├── auth_controller.dart
│   │   │   ├── auth_dependecy.dart
│   │   │   ├── auth_entity.dart
│   │   │   ├── auth_param.dart
│   │   │   ├── auth_repository.dart
│   │   │   ├── auth_routes.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── auth.dart
│   │   │   └── signup_request.dart
│   │   └── modules.dart
│   └── server
│       └── server.dart
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── test
    └── server_test.dart

├── config
├── app_config.dart:
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

── environment.dart:
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
├── database
├── database_connection.dart:
abstract class DatabaseConnection {
  Future<void> connect();

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]);

  Future<int> execute(String sql, [List<dynamic>? params]);

  /// Executa uma transação e entrega uma conexão transacional (tx)
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action);
}


├── db.dart:
import 'package:sympllizy_back/core/database/database_connection.dart';

class DB {
  static late final DatabaseConnection _instance;

  DB._();

  static void init(DatabaseConnection connection) {
    _instance = connection;
  }

  static DatabaseConnection get instance => _instance;
}

└── postgres_connection.dart:
import 'package:postgres/postgres.dart';

import 'database_connection.dart';

class PostgresConnection extends DatabaseConnection {
  final String url;
  Connection? _conn;

  PostgresConnection(this.url);

  @override
  Future<void> connect() async {
    final uri = Uri.parse(url);

    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':')[1] : null,
    );

    _conn = await Connection.open(endpoint, settings: const ConnectionSettings(sslMode: SslMode.disable));

    print('[DB] Conectado com sucesso!');
  }

  Connection get raw => _conn!;

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    final conn = _conn!;
    final result = await conn.execute(sql, parameters: params);

    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    final conn = _conn!;
    final result = await conn.execute(sql, parameters: params);

    return result.affectedRows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action) async {
    final conn = _conn!;
    return await conn.runTx((session) async {
      final txConn = _TxPostgresConnection(session);
      return await action(txConn);
    });
  }
}

/// Conexão usada **dentro** de uma transação
class _TxPostgresConnection extends DatabaseConnection {
  final Session _session;

  _TxPostgresConnection(this._session);

  @override
  Future<void> connect() async {
    // Não faz nada em tx
    return;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    final result = await _session.execute(sql, parameters: params);

    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    final result = await _session.execute(sql, parameters: params);
    return result.affectedRows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action) {
    throw UnsupportedError('Transação dentro de transação não suportada');
  }
}

├── env
└── env.dart:
import 'dart:io';

class Env {
  static final Map<String, String> _cache = {};

  static void load({String file = '.env'}) {
    final f = File(file);

    if (!f.existsSync()) {
      throw Exception("Arquivo .env não encontrado em: ${f.path}");
    }

    final lines = f.readAsLinesSync();

    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      final index = line.indexOf('=');
      if (index == -1) continue;

      final key = line.substring(0, index).trim();
      var value = line.substring(index + 1).trim();

      // remove aspas se existirem
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      _cache[key] = value;
    }

    print("[ENV] Carregado: ${_cache.length} variáveis");
  }

  static String get(String key, {String? fallback}) {
    if (_cache.containsKey(key)) return _cache[key]!;

    if (fallback != null) return fallback;

    throw Exception("ENV $key não definido");
  }
}

├── errors
├── unauthorized_exception.dart:
import 'base_exception.dart';

class UnauthorizedException extends BaseException {
  UnauthorizedException(super.message, {String? code, super.details}) : super(code: code ?? 'unauthorized', statusCode: 401);
}

├── auth_exception.dart:
import 'base_exception.dart';

class AuthException extends BaseException {
  AuthException(super.message, {String? code, super.details}) : super(code: code ?? 'auth_error', statusCode: 401);
}

├── base_exception.dart:
class BaseException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  BaseException(this.message, {this.statusCode = 400, this.code, this.details});

  @override
  String toString() => 'BaseException($statusCode, $code, $message)';
}

├── forbidden_exception.dart:
import 'base_exception.dart';

class ForbiddenException extends BaseException {
  ForbiddenException(super.message, {String? code, super.details}) : super(code: code ?? 'forbidden', statusCode: 403);
}

├── not_found_exception.dart:
import 'base_exception.dart';

class NotFoundException extends BaseException {
  NotFoundException(super.message, {String? code, super.details}) : super(code: code ?? 'not_found', statusCode: 404);
}

├── server_exception.dart:
import 'base_exception.dart';

class ServerException extends BaseException {
  ServerException(super.message, {String? code, super.details}) : super(code: code ?? 'server_error', statusCode: 500);
}

└── validation_exception.dart:
import 'base_exception.dart';

class ValidationException extends BaseException {
  ValidationException(super.message, {super.details, String? code}) : super(code: code ?? 'validation_error', statusCode: 400);
}

├── http
├── api_response.dart:
class ApiResponse {
  static Map<String, dynamic> success({String message = 'OK', dynamic data}) {
    return {'success': true, 'message': message, 'data': data};
  }

  static Map<String, dynamic> error({String message = 'Erro', dynamic data}) {
    return {'success': false, 'message': message, 'data': data};
  }
}

├── context.dart:
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


├── http_to_shelf.dart:
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

├── request_utils.dart:
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

├── response_utils.dart:
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

├── router.dart:
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

  void group(String prefix, void Function(Router router) register, {List<Middleware> middlewares = const []}) {
    final child = _GroupedRouter(parent: this, prefix: prefix, inheritedMiddlewares: [..._middlewares, ...middlewares]);

    register(child);
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

class _GroupedRouter extends Router {
  final Router parent;
  final String prefix;
  final List<Middleware> inheritedMiddlewares;

  _GroupedRouter({required this.parent, required this.prefix, required this.inheritedMiddlewares});

  String _fullPath(String path) {
    if (path.startsWith('/')) {
      return prefix + path;
    }
    return '$prefix/$path';
  }

  // ===========================================================
  //               OVERRIDE DE TODOS OS MÉTODOS HTTP
  // ===========================================================

  @override
  void get(String path, Handler handler) {
    parent._add('GET', _fullPath(path), _wrap(handler));
  }

  @override
  void post(String path, Handler handler) {
    parent._add('POST', _fullPath(path), _wrap(handler));
  }

  @override
  void put(String path, Handler handler) {
    parent._add('PUT', _fullPath(path), _wrap(handler));
  }

  @override
  void delete(String path, Handler handler) {
    parent._add('DELETE', _fullPath(path), _wrap(handler));
  }

  @override
  void patch(String path, Handler handler) {
    parent._add('PATCH', _fullPath(path), _wrap(handler));
  }

  @override
  void options(String path, Handler handler) {
    parent._add('OPTIONS', _fullPath(path), _wrap(handler));
  }

  // ===========================================================
  //                    WRAPPER DE MIDDLEWARES
  // ===========================================================

  Handler _wrap(Handler handler) {
    return (ctx) async {
      var index = -1;

      Future<void> run() async {
        index++;
        if (index < inheritedMiddlewares.length) {
          await inheritedMiddlewares[index](ctx, run);
        } else {
          await handler(ctx);
        }
      }

      await run();
    };
  }

  // Estes não precisam existir no group (evita duplicação)
  @override
  void use(Middleware middleware) {
    throw UnsupportedError("Use middlewares no group via parâmetro 'middlewares:'");
  }

  @override
  Future<void> handle(HttpRequest request) {
    throw UnsupportedError("Group não deve chamar handle().");
  }
}


└── shelf_to_http.dart:
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

├── logging
│   ├── audit_logger.dart:
import 'package:sympllizy_back/core/logging/logging.dart';

import '../core.dart';

class AuditLogger {
  final Logger logger;

  AuditLogger(this.logger);

  Future<void> log({required String action, required String entity, required String entityId, required HttpContext ctx, Map<String, dynamic>? changes}) {
    return logger.log(
      LogEntry(
        level: LogLevel.info,
        type: 'audit',
        message: '$action $entity',
        userId: ctx.locals['userId'],
        orgId: ctx.locals['orgId'],
        context: {'entity': entity, 'entity_id': entityId, 'changes': changes},
      ),
    );
  }
}

│   ├── db_logger.dart:
import '../database/database_connection.dart';
import 'log_entry.dart';
import 'log_level.dart';
import 'logger.dart';

class DbLogger implements Logger {
  final DatabaseConnection db;

  DbLogger(this.db);

  @override
  Future<void> log(LogEntry e) async {
    await db.execute(
      '''
      INSERT INTO data.logs (
        level, type, message, context,
        user_id, org_id,
        method, path, status_code,
        ip, user_agent
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [e.level.name, e.type, e.message, e.context, e.userId, e.orgId, e.method, e.path, e.statusCode, e.ip, e.userAgent],
    );
  }

  @override
  Future<void> info(String type, String message, {Map<String, dynamic>? ctx}) {
    return log(LogEntry(level: LogLevel.info, type: type, message: message, context: ctx));
  }

  @override
  Future<void> error(String type, String message, {Map<String, dynamic>? ctx}) {
    return log(LogEntry(level: LogLevel.error, type: type, message: message, context: ctx));
  }
}

│   ├── log_entry.dart:
import 'log_level.dart';

class LogEntry {
  final LogLevel level;
  final String type;
  final String message;
  final Map<String, dynamic>? context;

  final String? userId;
  final String? orgId;

  final String? method;
  final String? path;
  final int? statusCode;

  final String? ip;
  final String? userAgent;

  LogEntry({required this.level, required this.type, required this.message, this.context, this.userId, this.orgId, this.method, this.path, this.statusCode, this.ip, this.userAgent});
}

│   ├── log_level.dart:
enum LogLevel { info, warn, error }

│   ├── logger.dart:
import 'package:sympllizy_back/core/logging/log_entry.dart';

abstract class Logger {
  Future<void> log(LogEntry entry);

  Future<void> info(String type, String message, {Map<String, dynamic>? ctx});
  Future<void> error(String type, String message, {Map<String, dynamic>? ctx});
}


│   └── request_logger.dart:
import 'package:sympllizy_back/core/core.dart';

Middleware requestLogger(Logger logger) {
  return (HttpContext ctx, next) async {
    final start = DateTime.now();

    try {
      await next();

      final duration = DateTime.now().difference(start).inMilliseconds;

      await logger.log(
        LogEntry(
          level: LogLevel.info,
          type: 'access',
          message: 'HTTP ${ctx.method} ${ctx.path}',
          method: ctx.method,
          path: ctx.path,
          statusCode: ctx.response.statusCode,
          userId: ctx.locals['userId'],
          orgId: ctx.locals['orgId'],
          ip: ctx.ip,
          userAgent: ctx.userAgent,
          context: {'duration_ms': duration},
        ),
      );
    } catch (e) {
      rethrow;
    }
  };
}



├── middleware
├── auth_middleware.dart:
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

├── cors_middleware.dart:
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

├── error_middleware.dart:
import 'dart:io';

import 'package:sympllizy_back/core/http/response_utils.dart';
import 'package:sympllizy_back/core/logging/logging.dart';

import '../http/api_response.dart';
import '../http/context.dart';

Future<void> errorMiddleware(Object error, StackTrace stack, HttpContext ctx) async {
  final logger = ctx.locals['logger'] as Logger?;

  await logger?.log(
    LogEntry(
      level: LogLevel.error,
      type: 'error',
      message: error.toString(),
      context: {'stack': stack.toString()},
      userId: ctx.locals['userId'],
      orgId: ctx.locals['orgId'],
      method: ctx.method,
      path: ctx.path,
      ip: ctx.ip,
      userAgent: ctx.userAgent,
    ),
  );

  sendJson(ctx, HttpStatus.internalServerError, ApiResponse.error(message: 'Erro interno'));
}


├── logging_middleware.dart:
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

└── require_role.dart:
import 'package:sympllizy_back/core/errors/forbidden_exception.dart';
import 'package:sympllizy_back/core/http/router.dart';

Middleware requireRole(String role) {
  return (ctx, next) async {
    final roles = (ctx.locals['roles'] as List<String>?) ?? [];

    if (!roles.contains(role)) {
      throw ForbiddenException('Permissão insuficiente');
    }

    await next();
  };
}

└── jwt_middleware.dart:
import '../core.dart';

Middleware jwtMiddleware(JwtService jwtService) {
  return (HttpContext ctx, Future<void> Function() next) async {
    final authHeader = ctx.header('authorization');

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw UnauthorizedException('Token não informado');
    }

    final token = authHeader.substring(7).trim();

    try {
      final jwt = jwtService.verifyAccessToken(token);

      // ✅ USAR O SERVICE (não o JWT direto)
      ctx.locals['userId'] = jwtService.getUserId(jwt);
      ctx.locals['orgId'] = jwtService.getOrgId(jwt);
      ctx.locals['roles'] = jwtService.getRoles(jwt);

      await next();
    } catch (e) {
      throw UnauthorizedException('Token inválido ou expirado');
    }
  };
}


└── org_context_middleware.dart:
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


├── openapi
├── openapi.dart:
import 'dart:convert';

class OpenApiOperation {
  final String summary;
  final String? description;
  final OpenApiRequestBody? requestBody;
  final Map<String, dynamic> responses;

  OpenApiOperation({required this.summary, this.description, this.requestBody, required this.responses});

  Map<String, dynamic> toJson() {
    final map = {'summary': summary, 'responses': responses};

    if (description != null) {
      map['description'] = description!;
    }

    if (requestBody != null) {
      map['requestBody'] = requestBody!.toJson();
    }

    return map;
  }
}

class OpenApiRequestBody {
  final bool required;
  final Map<String, dynamic> content;

  OpenApiRequestBody({this.required = false, required this.content});

  Map<String, dynamic> toJson() {
    return {'required': required, 'content': content};
  }
}

class OpenApi {
  static final Map<String, dynamic> _paths = {};

  /// Registra uma operação OpenAPI para um método + caminho
  static void addOperation({required String method, required String path, required OpenApiOperation operation}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final upperMethod = method.toLowerCase();

    // Se não existir ainda, cria o path
    if (!_paths.containsKey(normalizedPath)) {
      _paths[normalizedPath] = {};
    }

    // Adiciona a operação específica (get/post/put...)
    _paths[normalizedPath][upperMethod] = operation.toJson();
  }

  /// Retorna o JSON completo para o Swagger
  static String json() {
    final doc = {
      'openapi': '3.0.0',
      'info': {'title': 'Sympllizy API', 'version': '1.0.0'},
      'paths': _paths,
    };

    return jsonEncode(doc);
  }
}


└── openapi.yaml:
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

├── routes

└── test_route.dart:
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


├── security
├── jwt_service.dart:
// lib/core/security/jwt_service.dart
// lib/core/security/jwt_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sympllizy_back/core/security/token_pair.dart';

import '../env/env.dart';

class JwtService {
  final String _secret;
  final String _issuer;

  final Duration accessTokenDuration;
  final Duration refreshTokenDuration;

  JwtService({String? secret, String? issuer, this.accessTokenDuration = const Duration(minutes: 30), this.refreshTokenDuration = const Duration(days: 7)})
    : _secret = secret ?? Env.get('JWT_SECRET'),
      _issuer = issuer ?? Env.get('JWT_ISSUER');

  TokenPair generateTokens({required String userId, required String orgId, List<String> roles = const []}) {
    final now = DateTime.now();
    final accessExp = now.add(accessTokenDuration);
    final refreshExp = now.add(refreshTokenDuration);
    // ACCESS TOKEN --------------------------------------------------------
    final accessJwt = JWT(
      {'org': orgId, 'roles': roles, 'type': 'access', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': accessExp.millisecondsSinceEpoch ~/ 1000},
      issuer: _issuer,
      subject: userId,
    );
    final accessToken = accessJwt.sign(SecretKey(_secret));
    // REF
    // REF
    // REFRESH TOKEN --------------------------------------------------------
    final refreshJwt = JWT({'org': orgId, 'type': 'refresh', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': refreshExp.millisecondsSinceEpoch ~/ 1000}, issuer: _issuer, subject: userId);
    final refreshToken = refreshJwt.sign(SecretKey(_secret));
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken, accessExpiresAt: accessExp.millisecondsSinceEpoch ~/ 1000, refreshExpiresAt: refreshExp.millisecondsSinceEpoch ~/ 1000);
  }

  TokenPair generateTokenPair({required String userId, required String orgId, List<String> roles = const []}) {
    final now = DateTime.now();
    final accessExp = now.add(accessTokenDuration);
    final refreshExp = now.add(refreshTokenDuration);

    // ACCESS TOKEN --------------------------------------------------------
    final accessJwt = JWT(
      {'org': orgId, 'roles': roles, 'type': 'access', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': accessExp.millisecondsSinceEpoch ~/ 1000},
      issuer: _issuer,
      subject: userId,
    );

    final accessToken = accessJwt.sign(SecretKey(_secret));

    // REFRESH TOKEN --------------------------------------------------------
    final refreshJwt = JWT({'org': orgId, 'type': 'refresh', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': refreshExp.millisecondsSinceEpoch ~/ 1000}, issuer: _issuer, subject: userId);

    final refreshToken = refreshJwt.sign(SecretKey(_secret));

    return TokenPair(accessToken: accessToken, refreshToken: refreshToken, accessExpiresAt: accessExp.millisecondsSinceEpoch ~/ 1000, refreshExpiresAt: refreshExp.millisecondsSinceEpoch ~/ 1000);
  }

  // -----------------------------------------------------------------------
  static JwtService createFromEnv() => JwtService();
  JWT verifyAccessToken(String token) {
    final jwt = _verify(token);
    if (jwt.payload['type'] != 'access') {
      throw JWTException('Invalid token type');
    }
    return jwt;
  }

  JWT verifyRefreshToken(String token) {
    final jwt = _verify(token);
    if (jwt.payload['type'] != 'refresh') {
      throw JWTException('Invalid token type');
    }
    return jwt;
  }

  JWT _verify(String token) {
    try {
      return JWT.verify(token, SecretKey(_secret));
    } on JWTExpiredException {
      throw JWTException('Token expired');
    } on JWTException catch (e) {
      throw JWTException(e.message);
    }
  }

  String getUserId(JWT jwt) => jwt.subject ?? '';

  String getOrgId(JWT jwt) => jwt.payload['org'] as String? ?? '';

  List<String> getRoles(JWT jwt) {
    final roles = jwt.payload['roles'];
    if (roles is List) {
      return roles.whereType<String>().toList();
    }
    return [];
  }
}


├── password_hash.dart:
import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher();

  String hash(String password) {
    // Futuro: adicionar salt/pepper
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verify(String password, String hashValue) {
    return hash(password) == hashValue;
  }
}


├── security.dart:

└── token_pair.dart:

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int accessExpiresAt;
  final int refreshExpiresAt;

  const TokenPair({required this.accessToken, required this.refreshToken, required this.accessExpiresAt, required this.refreshExpiresAt});
}

└── swagger
├── openapi_spec.dart:
import '../openapi/openapi.dart';

class OpenApiSpec {
  static String get spec => OpenApi.json();
}

└── swagger_handler.dart:
import 'package:shelf/shelf.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import 'openapi_spec.dart';

class SwaggerHandler {
  static Handler get handler => SwaggerUI(OpenApiSpec.spec, title: 'Sympllizy API Docs', specType: SpecType.json, docExpansion: DocExpansion.list, deepLink: true, persistAuthorization: true).call;
}
└── server
└── server.dart:
import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/core/swagger/swagger_handler.dart';
import 'package:sympllizy_back/modules/auth/auth_dependecy.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // ============ CONFIGURAÇÃO BÁSICA ============
  router.setErrorHandler(errorMiddleware);

  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);

  // ============ OPENAPI (REGISTRO GLOBAL) ============
  OpenApi.addOperation(
    method: 'get',
    path: '/health',
    operation: OpenApiOperation(
      summary: 'Health check da API',
      responses: {
        '200': {'description': 'API está rodando'},
      },
    ),
  );

  // ============ DEPENDÊNCIAS ============
  final db = DB.instance;
  final jwtService = JwtService.createFromEnv();
  const hasher = PasswordHasher();

  final authRoutes = authDependency(db: db, jwtService: jwtService, hasher: hasher);

  // ============ REGISTRO DE ROTAS (INCLUI /auth/...) -----------
  authRoutes.register(router);

  // ============ ROTAS DE DOC -----------
  router.get('/openapi.json', (ctx) async {
    final json = OpenApi.json();

    ctx.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(json);

    await ctx.response.close();
  });

  router.get('/docs', (ctx) async {
    final shelfReq = await httpToShelfRequest(ctx.request);
    final shelfRes = await SwaggerHandler.handler(shelfReq);
    await sendShelfResponse(ctx.response, shelfRes);
  });

  router.get('/docs/:rest', (ctx) async {
    final shelfReq = await httpToShelfRequest(ctx.request);
    final shelfRes = await SwaggerHandler.handler(shelfReq);
    await sendShelfResponse(ctx.response, shelfRes);
  });

  // ============ HEALTH ============
  router.get('/health', (ctx) async {
    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
    return;
  });

  // ============ INICIAR SERVIDOR ============
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}


Modulo ==>
├── modules
│   │   ├── auth
│   │   │   ├── auth_controller.dart:
import 'dart:developer';

import 'package:sympllizy_back/core/core.dart';

import 'auth_service.dart';

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  Future<void> signup(HttpContext ctx) async {
    try {
      final body = await ctx.bodyAsJson();

      final orgName = body['org_name'];
      final email = body['email'];
      final password = body['password'];
      final fullName = body['full_name'];

      if (orgName == null || email == null || password == null) {
        throw ValidationException(
          'Dados inválidos',
          details: {
            'required': ['org_name', 'email', 'password'],
          },
        );
      }

      final entity = await _service.signup(orgName: orgName, email: email, password: password, fullName: fullName);

      // 👇 AQUI está a correção principal: usamos toMap()
      sendJson(ctx, 201, ApiResponse.success(message: "Conta criada com sucesso", data: entity.toMap()));
    } on ValidationException catch (e) {
      sendJson(ctx, 400, ApiResponse.error(message: e.message, data: e.details));
    } catch (e, stack) {
      log("Erro em signup", error: e, stackTrace: stack);
      sendJson(ctx, 500, ApiResponse.error(message: "Erro interno"));
    }
  }
}


│   │   │   ├── auth_dependecy.dart:
import 'package:sympllizy_back/modules/auth/auth_controller.dart';
import 'package:sympllizy_back/modules/auth/auth_repository.dart';
import 'package:sympllizy_back/modules/auth/auth_routes.dart';
import 'package:sympllizy_back/modules/auth/auth_service.dart';

import '../../core/core.dart';

AuthRoutes authDependency({required DatabaseConnection db, required JwtService jwtService, required PasswordHasher hasher}) {
  final authRepository = AuthRepositoryImpl(db);
  final authService = AuthServiceImpl(authRepository, db, jwtService, hasher);
  final authController = AuthController(authService);

  return AuthRoutes(authController);
}

│   │   │   ├── auth_entity.dart:
import 'package:sympllizy_back/core/core.dart';

class AuthEntity {
  final String userId;
  final String email;
  final String? fullName;
  final OrgEntity org;
  final CompanyEntity company;
  final TokenPair tokens;

  AuthEntity({required this.userId, required this.email, this.fullName, required this.org, required this.company, required this.tokens});

  factory AuthEntity.fromMap(Map<String, dynamic> map) {
    return AuthEntity(
      userId: map['user']['id'] as String,
      email: map['user']['email'] as String,
      fullName: map['user']['full_name'] as String?,
      org: OrgEntity.fromMap(map['org'] as Map<String, dynamic>),
      company: CompanyEntity.fromMap(map['company'] as Map<String, dynamic>),
      tokens: TokenPair(
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
        accessExpiresAt: map['access_expires_at'] as int,
        refreshExpiresAt: map['refresh_expires_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'access_expires_at': tokens.accessExpiresAt,
      'refresh_expires_at': tokens.refreshExpiresAt,
      'user': {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'roles': ['owner'],
      },
      'org': org.toMap(),
      'company': company.toMap(),
    };
  }
}

class CompanyEntity {
  final String id;
  final String name;

  CompanyEntity({required this.id, required this.name});

  factory CompanyEntity.fromMap(Map<String, dynamic> map) {
    return CompanyEntity(id: map['id'] as String, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}

class OrgEntity {
  final String id;
  final String name;
  final String slug;

  OrgEntity({required this.id, required this.name, required this.slug});

  factory OrgEntity.fromMap(Map<String, dynamic> map) {
    return OrgEntity(id: map['id'] as String, name: map['name'] as String, slug: map['slug'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

│   │   │   ├── auth_param.dart:
class AuthParam {
  final String email;
  final String password;
  final String fullName;
  final String orgName;
  AuthParam({required this.email, required this.password, required this.fullName, required this.orgName});

  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password, 'full_name': fullName, 'org_name': orgName};
  }
}

│   │   │   ├── auth_repository.dart:
import 'package:sympllizy_back/core/core.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>?> findUserByEmail(String email);

  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug);

  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash);

  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName);

  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role});

  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId);

  Future<void> saveRefreshToken(DatabaseConnection db, {required String userId, required String token, required DateTime expiresAt});
}

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseConnection _db; // para operações fora de tx (ex: findUserByEmail)

  AuthRepositoryImpl(this._db);

  // SQL constantes
  static const String selectUserByEmail = 'SELECT * FROM auth.users WHERE email = \$1 LIMIT 1';

  static const String insertOrg = '''
    INSERT INTO data.orgs (name, slug)
    VALUES (\$1, \$2)
    RETURNING id, name, slug
  ''';

  static const String insertUser = '''
    INSERT INTO auth.users (email, password_hash, is_active)
    VALUES (\$1, \$2, true)
    RETURNING id, email, created_at
  ''';

  static const String insertUserProfile = '''
    INSERT INTO data.user_profiles (user_id, full_name)
    VALUES (\$1, \$2)
  ''';

  static const String insertUserToOrg = '''
    INSERT INTO data.org_users (user_id, org_id, role)
    VALUES (\$1, \$2, \$3)
  ''';

  static const String insertDefaultCompany = '''
    INSERT INTO data.companies (org_id, name)
    VALUES (\$1, 'Matriz')
    RETURNING id, name
  ''';

  static const String insertRefreshToken = '''
    INSERT INTO auth.refresh_tokens (user_id, token, expires_at)
    VALUES (\$1, \$2, \$3)
  ''';

  @override
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final result = await _db.query(selectUserByEmail, [email]);
    if (result.isEmpty) return null;
    return result.first;
  }

  @override
  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug) async {
    final rows = await db.query(insertOrg, [name, slug]);
    return rows.first;
  }

  @override
  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash) async {
    final rows = await db.query(insertUser, [email, passwordHash]);
    return rows.first;
  }

  @override
  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName) async {
    await db.execute(insertUserProfile, [userId, fullName]);
  }

  @override
  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role = 'owner'}) async {
    await db.execute(insertUserToOrg, [userId, orgId, role]);
  }

  @override
  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId) async {
    final rows = await db.query(insertDefaultCompany, [orgId]);
    return rows.first;
  }

  @override
  Future<void> saveRefreshToken(DatabaseConnection db, {required String userId, required String token, required DateTime expiresAt}) async {
    await db.execute(insertRefreshToken, [userId, token, expiresAt.toUtc()]);
  }
}


│   │   │   ├── auth_routes.dart:
import 'package:sympllizy_back/core/core.dart';

import 'auth_controller.dart';

class AuthRoutes {
  final AuthController controller;

  AuthRoutes(this.controller);

  void register(Router router) {
    OpenApi.addOperation(
      method: 'post',
      path: '/auth/signup',
      operation: OpenApiOperation(
        summary: 'Criação de conta (Org + Usuário)',
        description: 'Cria uma organização, um usuário proprietário (owner) e a empresa matriz.',
        requestBody: OpenApiRequestBody(
          required: true,

          content: {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'org_name': {'type': 'string', 'example': 'Minha Empresa'},
                  'email': {'type': 'string', 'example': 'admin@empresa.com'},
                  'password': {'type': 'string', 'example': 'senha123'},
                  'full_name': {'type': 'string', 'example': 'Gabriel Lima'},
                },
                'required': ['org_name', 'email', 'password'],
              },
            },
          },
        ),
        responses: {
          '201': {
            'description': 'Conta criada com sucesso',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'example': {
                    "success": true,
                    "message": "Conta criada com sucesso",
                    "data": {
                      "access_token": "jwt_access_here",
                      "refresh_token": "jwt_refresh_here",
                      "user": {
                        "id": "uuid",
                        "email": "admin@empresa.com",
                        "full_name": "Gabriel Lima",
                        "roles": ["owner"],
                      },
                      "org": {"id": "uuid", "name": "Minha Empresa", "slug": "minha-empresa"},
                      "company": {"id": "uuid", "name": "Matriz"},
                    },
                  },
                },
              },
            },
          },
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );

    router.group('/auth', (r) {
      r.post('/signup', controller.signup);
    });
  }
}


│   │   │   ├── auth_service.dart:
import 'package:sympllizy_back/core/core.dart';

import 'auth_entity.dart';
import 'auth_repository.dart';

abstract class AuthService {
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName});
}

class AuthServiceImpl implements AuthService {
  final DatabaseConnection _db;
  final AuthRepository _repo;
  final JwtService _jwt;
  final PasswordHasher _hasher;

  AuthServiceImpl(this._repo, this._db, this._jwt, this._hasher);

  String _slugify(String value) {
    final lower = value.trim().toLowerCase();
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), '').replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'-+'), '-');
    return slug.isEmpty ? 'org' : slug;
  }

  @override
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName}) async {
    // validações básicas
    if (orgName.trim().length < 3) {
      throw ValidationException('Nome da organização muito curto', details: {'org_name': 'min 3 caracteres'});
    }

    if (!email.contains('@')) {
      throw ValidationException('E-mail inválido', details: {'email': 'formato inválido'});
    }

    if (password.length < 6) {
      throw ValidationException('Senha muito curta', details: {'password': 'min 6 caracteres'});
    }

    // checa se user já existe (fora da tx mesmo)
    final existing = await _repo.findUserByEmail(email);
    if (existing != null) {
      throw ValidationException('E-mail já está em uso', details: {'email': 'já cadastrado'});
    }

    final slug = _slugify(orgName);
    final passwordHash = _hasher.hash(password);

    // 🔥 Agora sim: tudo que é crítico vai dentro de 1 transação
    return await _db.transaction((tx) async {
      final org = await _repo.createOrg(tx, orgName, slug);
      final orgId = org['id'].toString();

      final user = await _repo.createUser(tx, email, passwordHash);
      final userId = user['id'].toString();

      await _repo.createUserProfile(tx, userId, fullName);

      await _repo.addUserToOrg(tx, userId: userId, orgId: orgId, role: 'owner');

      final company = await _repo.createDefaultCompany(tx, orgId);

      final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: const ['owner']);

      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));

      return AuthEntity(
        userId: userId,
        email: email,
        fullName: fullName,
        org: OrgEntity(id: orgId, name: org['name'] as String, slug: org['slug'] as String),
        company: CompanyEntity(id: company['id'].toString(), name: company['name'] as String),
        tokens: tokens,
      );
    });
  }
}


│   │   │   └── signup_request.dart:
class SignupRequest {
  final String orgName;
  final String email;
  final String password;
  final String? fullName;

  SignupRequest({required this.orgName, required this.email, required this.password, this.fullName});

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(orgName: json['org_name'], email: json['email'], password: json['password'], fullName: json['full_name']);
  }
}
