iby3l@192 sympllizy_back % tree
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
├── core
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

├── config.dart:
export 'app_config.dart';
export 'environment.dart';

└── environment.dart:
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


├── core.dart:

├── database
├── database_connection.dart:
abstract class DatabaseConnection {
  Future<void> connect();

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]);

  Future<int> execute(String sql, [List<dynamic>? params]);

  /// Executa uma transação e entrega uma conexão transacional (tx)
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action);
}

├── database.dart:
export 'database_connection.dart';
export 'db.dart';
export 'postgres_connection.dart';

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

├── erros.dart:
export 'auth_exception.dart';
export 'base_exception.dart';
export 'forbidden_exception.dart';
export 'not_found_exception.dart';
export 'server_exception.dart';
export 'unauthorized_exception.dart';
export 'validation_exception.dart';

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

├── unauthorized_exception.dart:
import 'base_exception.dart';

class UnauthorizedException extends BaseException {
  UnauthorizedException(super.message, {String? code, super.details}) : super(code: code ?? 'unauthorized', statusCode: 401);
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

├── http_body.dart:
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

├── http_context_auth.dart:
import 'package:sympllizy_back/core/errors/unauthorized_exception.dart';

import 'context.dart';

class AuthContext {
  final String userId;
  final String orgId;
  final List<String> roles;

  AuthContext({required this.userId, required this.orgId, required this.roles});
}

extension HttpContextAuth on HttpContext {
  static const _key = '_auth';

  AuthContext get auth {
    final value = items[_key];
    if (value is! AuthContext) {
      throw UnauthorizedException('Usuário não autenticado');
    }
    return value;
  }

  bool get isAuthenticated => items.containsKey(_key);

  void setAuth(AuthContext auth) {
    items[_key] = auth;
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

├── http.dart:
export 'api_response.dart';
export 'context.dart';
export 'http_body.dart';
export 'http_context_auth.dart';
export 'http_to_shelf.dart';
export 'request_utils.dart';
export 'response_utils.dart';
export 'router.dart';
export 'shelf_to_http.dart';

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

/// Encadeia middlewares + handler final.
/// Uso: router.post('/x', chain([mw1, mw2], (ctx) async { ... }));
Handler chain(List<Middleware> middlewares, Handler handler) {
  return (ctx) async {
    var i = -1;

    Future<void> run() async {
      i++;
      if (i < middlewares.length) {
        await middlewares[i](ctx, run);
      } else {
        await handler(ctx);
      }
    }

    await run();
  };
}

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
├── audit_logger.dart:
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

├── db_logger.dart:
import 'dart:convert';

import '../database/database_connection.dart';
import 'log_entry.dart';
import 'logger.dart';

class DbLogger extends Logger {
  final DatabaseConnection db;

  DbLogger(this.db);
  @override
  Future<void> log(LogEntry entry) async {
    await db.execute(
      '''
      INSERT INTO data.logs (
        level,
        type,
        message,
        context,
        request_id,
        method,
        path,
        status_code,
        user_id,
        org_id,
        ip,
        user_agent,
        created_at
      )
      VALUES (
        \$1, \$2, \$3, \$4,
        \$5, \$6, \$7, \$8,
        \$9, \$10, \$11, \$12,
        NOW()
      )
      ''',
      [
        entry.level.name,
        entry.type,
        entry.message,
        entry.context != null ? jsonEncode(entry.context) : null,
        entry.requestId,
        entry.method,
        entry.path,
        entry.statusCode,
        entry.userId,
        entry.orgId,
        entry.ip,
        entry.userAgent,
      ],
    );
  }
}

├── log_entry.dart:
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

  final String? requestId;

  LogEntry({required this.level, required this.type, required this.message, this.context, this.userId, this.orgId, this.method, this.path, this.statusCode, this.ip, this.userAgent, this.requestId});
}

├── log_level.dart:
enum LogLevel { info, warn, error }

├── logger.dart:
import 'package:sympllizy_back/core/logging/log_entry.dart';

import 'log_level.dart';

abstract class Logger {
  Future<void> log(LogEntry entry);

  Future<void> info(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.info, type: type, message: message, context: context));
  }

  Future<void> error(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.error, type: type, message: message, context: context));
  }

  Future<void> warning(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.warn, type: type, message: message, context: context));
  }
}

├── logging.dart:
export 'audit_logger.dart';
export 'db_logger.dart';
export 'log_entry.dart';
export 'log_level.dart';
export 'logger.dart';
export 'request_logger.dart';

└── request_logger.dart:
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

├── logger_context_middleware.dart:
import '../core.dart';

Middleware loggerContextMiddleware(Logger logger) {
  return (ctx, next) async {
    ctx.locals['logger'] = logger;
    await next();
  };
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

├── middleware.dart:
export 'auth_middleware.dart';
export 'cors_middleware.dart';
export 'error_middleware.dart';
export 'logger_context_middleware.dart';
export 'logging_middleware.dart';
export 'org_context_middleware.dart';
export 'require_any_role.dart';
export 'require_auth.dart';

├── org_context_middleware.dart:
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

├── require_any_role.dart:
import '../core.dart';

Middleware requireAnyRole(List<String> roles) {
  return (ctx, next) async {
    if (!ctx.isAuthenticated) {
      throw UnauthorizedException('Autenticação necessária');
    }

    final allowed = ctx.auth?.roles.any(roles.contains) ?? false;

    if (!allowed) {
      throw ForbiddenException('Permissão insuficiente');
    }

    await next();
  };
}


└── require_auth.dart:
import '../core.dart';

Middleware requireAuth() {
  return (ctx, next) async {
    if (!ctx.isAuthenticated) {
      throw UnauthorizedException('Autenticação necessária');
    }
    await next();
  };
}


├── openapi

lib/core/openapi/openapi_bootstrap.dart
import 'openapi.dart';

void bootstrapOpenApi() {
  // ===== SERVERS =====
  OpenApi.addServer(url: 'http://localhost:8080', description: 'Local');

  // ===== TAGS =====
  OpenApi.addTag(name: 'Auth', description: 'Autenticação e sessão');
  OpenApi.addTag(name: 'Users', description: 'Usuário autenticado');
  OpenApi.addTag(name: 'Admin', description: 'Administração');
  OpenApi.addTag(name: 'System', description: 'Sistema');

  // ===== SECURITY =====
  OpenApi.addSecurityScheme('BearerAuth', {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT'});

  OpenApi.setGlobalSecurity([
    {'BearerAuth': []},
  ]);

  // ===== SCHEMAS BASE =====
  OpenApi.addSchema('ApiResponse', {
    'type': 'object',
    'properties': {
      'success': {'type': 'boolean'},
      'message': {'type': 'string'},
      'data': {'nullable': true},
    },
  });

  OpenApi.addSchema('Tokens', {
    'type': 'object',
    'properties': {
      'access_token': {'type': 'string'},
      'refresh_token': {'type': 'string'},
      'access_expires_at': {'type': 'integer'},
      'refresh_expires_at': {'type': 'integer'},
    },
  });

  OpenApi.addSchema('User', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string', 'format': 'uuid'},
      'email': {'type': 'string'},
      'roles': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  });

  OpenApi.addSchema('Org', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string', 'format': 'uuid'},
      'name': {'type': 'string'},
      'slug': {'type': 'string'},
    },
  });
}
lib/core/openapi/openapi.dart
import 'dart:convert';

class OpenApiOperation {
  final String summary;
  final String? description;
  final List<String>? tags;
  final OpenApiRequestBody? requestBody;
  final Map<String, dynamic> responses;
  final List<Map<String, List<String>>>? security;

  OpenApiOperation({required this.summary, this.description, this.tags, this.requestBody, required this.responses, this.security});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'summary': summary, 'responses': responses};

    if (description != null) map['description'] = description;
    if (tags != null) map['tags'] = tags;
    if (requestBody != null) map['requestBody'] = requestBody!.toJson();
    if (security != null) map['security'] = security;

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
  static final Map<String, dynamic> _schemas = {};
  static final Map<String, dynamic> _securitySchemes = {};
  static final List<Map<String, dynamic>> _tags = [];
  static final List<Map<String, dynamic>> _servers = [];
  static List<Map<String, List<String>>> _globalSecurity = [];

  // ================= TAGS =================
  static void addTag({required String name, String? description}) {
    _tags.add({'name': name, if (description != null) 'description': description});
  }

  // ================= SERVERS =================
  static void addServer({required String url, String? description}) {
    _servers.add({'url': url, if (description != null) 'description': description});
  }

  // ================= SCHEMAS =================
  static void addSchema(String name, Map<String, dynamic> schema) {
    _schemas[name] = schema;
  }

  // ================= SECURITY =================
  static void addSecurityScheme(String name, Map<String, dynamic> scheme) {
    _securitySchemes[name] = scheme;
  }

  static void setGlobalSecurity(List<Map<String, List<String>>> security) {
    _globalSecurity = security;
  }

  // ================= PATHS =================
  static void addOperation({required String method, required String path, required OpenApiOperation operation}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final lowerMethod = method.toLowerCase();

    _paths.putIfAbsent(normalizedPath, () => {});
    _paths[normalizedPath][lowerMethod] = operation.toJson();
  }

  // ================= FINAL JSON =================
  static String json() {
    final doc = <String, dynamic>{
      'openapi': '3.0.0',
      'info': {'title': 'Sympllizy API', 'version': '1.0.0', 'description': 'API oficial da plataforma Sympllizy'},
      'servers': _servers,
      'tags': _tags,
      'paths': _paths,
      'components': {if (_schemas.isNotEmpty) 'schemas': _schemas, if (_securitySchemes.isNotEmpty) 'securitySchemes': _securitySchemes},
      if (_globalSecurity.isNotEmpty) 'security': _globalSecurity,
    };

    return jsonEncode(doc);
  }
}

void registerOpenApiSecurity() {
  OpenApi.addSecurityScheme('BearerAuth', {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT', 'description': 'Informe o token no formato: Bearer {token}'});
}

├── openapi_config.dart:
import 'package:sympllizy_back/core/openapi/openapi.dart';

void registerBearerAuth() {
  OpenApi.addSecurityScheme('BearerAuth', {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT', 'description': 'Informe o token JWT no formato: Bearer {token}'});
}

├── openapi.dart:
import 'dart:convert';

class OpenApiOperation {
  final String summary;
  final String? description;
  final OpenApiRequestBody? requestBody;
  final Map<String, dynamic> responses;
  final List<Map<String, List<String>>>? security;

  OpenApiOperation({required this.summary, this.description, this.requestBody, required this.responses, this.security});

  Map<String, dynamic> toJson() {
    final map = {'summary': summary, 'responses': responses};

    if (description != null) {
      map['description'] = description!;
    }

    if (requestBody != null) {
      map['requestBody'] = requestBody!.toJson();
    }

    if (security != null) {
      map['security'] = security!;
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
  static final Map<String, dynamic> _securitySchemes = {};

  // =======================
  // SECURITY SCHEMES
  // =======================
  static void addSecurityScheme(String name, Map<String, dynamic> scheme) {
    _securitySchemes[name] = scheme;
  }

  // =======================
  // PATHS
  // =======================
  static void addOperation({required String method, required String path, required OpenApiOperation operation}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final lowerMethod = method.toLowerCase();

    _paths.putIfAbsent(normalizedPath, () => {});
    _paths[normalizedPath][lowerMethod] = operation.toJson();
  }

  // =======================
  // JSON FINAL
  // =======================
  static String json() {
    final doc = {
      'openapi': '3.0.0',
      'info': {'title': 'Sympllizy API', 'version': '1.0.0'},
      'paths': _paths,
      if (_securitySchemes.isNotEmpty) 'components': {'securitySchemes': _securitySchemes},
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
├── routes.dart:
export 'test_route.dart';

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
├── auth_payload.dart:
class AuthPayload {
  final String userId;
  final String orgId;
  final List<String> roles;

  AuthPayload({required this.userId, required this.orgId, required this.roles});
}


├── jwt_middleware.dart:
import 'dart:io';

import 'package:sympllizy_back/core/core.dart';

Middleware jwtMiddleware(JwtService jwt) {
  return (ctx, next) async {
    final authHeader = ctx.header('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return await next(); // deixa passar, requireAuth decide
    }

    final token = authHeader.substring(7);

    final decoded = jwt.verifyAccessToken(token);

    ctx.setAuth(AuthContext(userId: jwt.getUserId(decoded), orgId: jwt.getOrgId(decoded), roles: jwt.getRoles(decoded)));

    await next();
  };
}


├── jwt_service.dart:
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

  String getUserId(JWT jwt) {
    return jwt.payload['sub'] as String? ?? '';
  }

  String getOrgId(JWT jwt) {
    return jwt.payload['org'] as String? ?? '';
  }

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

├── require_role.dart:
import 'package:sympllizy_back/core/core.dart';

Middleware requireRole(String role) {
  return (ctx, next) async {
    if (!ctx.isAuthenticated || !ctx.auth.roles.contains(role)) {
      throw ForbiddenException('Permissão insuficiente');
    }
    await next();
  };
}

├── security.dart:
export 'auth_payload.dart';
export 'jwt_middleware.dart';
export 'jwt_service.dart';
export 'password_hash.dart';
export 'require_role.dart';
export 'token_pair.dart';

└── token_pair.dart:
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int accessExpiresAt;
  final int refreshExpiresAt;

  const TokenPair({required this.accessToken, required this.refreshToken, required this.accessExpiresAt, required this.refreshExpiresAt});
}


├── swagger
├── openapi_spec.dart:
import '../openapi/openapi.dart';

class OpenApiSpec {
  static String get spec => OpenApi.json();
}

├── swagger_handler.dart:
import 'package:shelf/shelf.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import 'openapi_spec.dart';

class SwaggerHandler {
  static Handler get handler => SwaggerUI(OpenApiSpec.spec, title: 'Sympllizy API Docs', specType: SpecType.json, docExpansion: DocExpansion.list, deepLink: true, persistAuthorization: true).call;
}

└── swagger.dart:
export 'openapi_spec.dart';
export 'swagger_handler.dart';

└── utils
    └── utils.dart:

├── modules
├── auth
├── auth_controller.dart:
import 'dart:developer';
import 'dart:io';

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

  Future<void> login(HttpContext ctx) async {
    final body = await readJson(ctx.request);

    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      throw ValidationException('Email e senha são obrigatórios', details: {'email': 'required', 'password': 'required'});
    }

    final result = await _service.login(email: email, password: password);

    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Login realizado com sucesso', data: result));
  }

  Future<void> refresh(HttpContext ctx) async {
    final body = await readJson(ctx.request);

    final refreshToken = body['refresh_token'] as String?;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ValidationException('Refresh token é obrigatório', details: {'refresh_token': 'obrigatório'});
    }

    final result = await _service.refresh(refreshToken);

    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Token renovado com sucesso', data: result));
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout(HttpContext ctx) async {
    final body = await ctx.bodyAsJson();
    final refreshToken = body['refresh_token'] as String?;

    if (refreshToken == null || refreshToken.isEmpty) {
      throw ValidationException('Refresh token obrigatório', details: {'refresh_token': 'required'});
    }

    await _service.logout(refreshToken);

    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Logout realizado com sucesso'));
  }

  // ---------------- LOGOUT GLOBAL ----------------
  Future<void> logoutAll(HttpContext ctx) async {
    final auth = ctx.auth;

    await _service.logoutAll(userId: auth.userId);

    sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'Logout global realizado com sucesso'));
  }
}


├── auth_dependecy.dart:
import 'package:sympllizy_back/modules/auth/auth_controller.dart';
import 'package:sympllizy_back/modules/auth/auth_repository.dart';
import 'package:sympllizy_back/modules/auth/auth_routes.dart';
import 'package:sympllizy_back/modules/auth/auth_service.dart';

import '../../core/core.dart';

AuthRoutes authDependency({required DatabaseConnection db, required JwtService jwtService, required PasswordHasher hasher, required Logger logger}) {
  final authRepository = AuthRepositoryImpl(db);
  final authService = AuthServiceImpl(authRepository, db, jwtService, hasher, logger);
  final authController = AuthController(authService);
  return AuthRoutes(authController, jwtService);
}

├── auth_entity.dart:
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

├── auth_param.dart:
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

├── auth_repository.dart:
import 'package:sympllizy_back/core/core.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>?> findUserByEmail(String email);

  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug);

  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash);

  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName);

  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role});

  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId);

  Future<Map<String, dynamic>> findPrimaryOrgByUser(String userId);
  Future<List<String>> findUserRoles(String userId, String orgId);

  Future<bool> findRefreshToken(DatabaseConnection tx, {required String userId, required String token});

  Future<void> revokeRefreshToken(DatabaseConnection tx, String token);

  Future<void> saveRefreshToken(DatabaseConnection tx, {required String userId, required String token, required DateTime expiresAt});

  Future<void> revokeAllRefreshTokens(DatabaseConnection tx, String userId);
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
  static const String selectPrimaryOrg = '''
  SELECT o.id, o.name, o.slug
  FROM data.orgs o
  JOIN data.org_users ou ON ou.org_id = o.id
  WHERE ou.user_id = \$1
  ORDER BY ou.created_at
  LIMIT 1
''';

  static const String selectRoles = '''
  SELECT role
  FROM data.org_users
  WHERE user_id = \$1 AND org_id = \$2
''';

  static const String selectRefreshToken = '''
SELECT 1
FROM auth.refresh_tokens
WHERE user_id = \$1
  AND token = \$2
  AND revoked_at IS NULL
  AND expires_at > NOW()
LIMIT 1
''';

  static const String revokeRefreshTokenSql = '''
UPDATE auth.refresh_tokens
SET revoked_at = NOW()
WHERE token = \$1
''';
  static const String revokeAllRefreshTokensSql = '''
UPDATE auth.refresh_tokens
SET revoked_at = NOW()
WHERE user_id = \$1
  AND revoked_at IS NULL
''';
  @override
  Future<void> revokeAllRefreshTokens(DatabaseConnection tx, String userId) async {
    await tx.execute(revokeAllRefreshTokensSql, [userId]);
  }

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
  Future<Map<String, dynamic>> findPrimaryOrgByUser(String userId) async {
    final rows = await _db.query(selectPrimaryOrg, [userId]);
    if (rows.isEmpty) {
      throw ForbiddenException('Usuário sem organização');
    }
    return rows.first;
  }

  @override
  Future<List<String>> findUserRoles(String userId, String orgId) async {
    final rows = await _db.query(selectRoles, [userId, orgId]);
    return rows.map((e) => e['role'].toString()).toList();
  }

  @override
  Future<bool> findRefreshToken(DatabaseConnection tx, {required String userId, required String token}) async {
    final rows = await tx.query(selectRefreshToken, [userId, token]);

    return rows.isNotEmpty;
  }

  @override
  Future<void> revokeRefreshToken(DatabaseConnection tx, String token) async {
    await tx.execute(revokeRefreshTokenSql, [token]);
  }

  @override
  Future<void> saveRefreshToken(DatabaseConnection tx, {required String userId, required String token, required DateTime expiresAt}) async {
    await tx.execute(insertRefreshToken, [userId, token, expiresAt.toUtc()]);
  }
}

├── auth_routes.dart:
import 'package:sympllizy_back/core/core.dart';

import 'auth_controller.dart';

class AuthRoutes {
  final AuthController controller;
  final JwtService jwtService;

  AuthRoutes(this.controller, this.jwtService);

  static const String _base = '/v1/auth';

  void register(Router router) {
    // =======================
    // ROTAS (VERSIONADAS)
    // =======================
    router.group(_base, (r) {
      r.post('/signup', controller.signup);
      r.post('/login', controller.login);
      r.post('/refresh', controller.refresh);

      // 🔐 precisa JWT (access) + body(refresh_token)
      r.post('/logout', chain([jwtMiddleware(jwtService), requireAuth()], controller.logout));

      // 🔐 precisa JWT (access)
      r.post('/logout-all', chain([jwtMiddleware(jwtService), requireAuth()], controller.logoutAll));
    });

    // =======================
    // SWAGGER
    // =======================
    _registerSchemas();
    _registerSignupSwagger();
    _registerLoginSwagger();
    _registerRefreshSwagger();
    _registerLogoutSwagger();
    _registerLogoutAllSwagger();
  }

  // ===========================================================================
  // SCHEMAS (reutilizáveis)
  // ===========================================================================
  void _registerSchemas() {
    // Requests
    OpenApi.addSchema('SignupRequest', {
      'type': 'object',
      'required': ['org_name', 'email', 'password'],
      'properties': {
        'org_name': {'type': 'string', 'example': 'Minha Empresa'},
        'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
        'password': {'type': 'string', 'format': 'password', 'example': 'senha123'},
        'full_name': {'type': 'string', 'example': 'Gabriel Lima'},
      },
    });

    OpenApi.addSchema('LoginRequest', {
      'type': 'object',
      'required': ['email', 'password'],
      'properties': {
        'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
        'password': {'type': 'string', 'format': 'password', 'example': '123456'},
      },
    });

    OpenApi.addSchema('RefreshRequest', {
      'type': 'object',
      'required': ['refresh_token'],
      'properties': {
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
      },
    });

    OpenApi.addSchema('LogoutRequest', {
      'type': 'object',
      'required': ['refresh_token'],
      'properties': {
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
      },
    });

    // Responses (data payloads)
    OpenApi.addSchema('AuthUser', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': '06a76be0-cabc-44c0-989d-fbfbd7c95ad1'},
        'email': {'type': 'string', 'example': 'admin@empresa.com'},
        'full_name': {'type': 'string', 'nullable': true, 'example': 'Gabriel Lima'},
        'roles': {
          'type': 'array',
          'items': {'type': 'string'},
          'example': ['owner'],
        },
      },
    });

    OpenApi.addSchema('AuthOrg', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': 'e9b73189-f499-4369-877a-3cf4526bfb8d'},
        'name': {'type': 'string', 'example': 'Minha Empresa'},
        'slug': {'type': 'string', 'example': 'minha-empresa'},
      },
    });

    OpenApi.addSchema('AuthCompany', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': '9692927d-9af6-4601-9437-832999028d26'},
        'name': {'type': 'string', 'example': 'Matriz'},
      },
    });

    OpenApi.addSchema('TokenPair', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string', 'example': 'jwt_access_here'},
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
        'access_expires_at': {'type': 'integer', 'example': 1765504344},
        'refresh_expires_at': {'type': 'integer', 'example': 1766107344},
      },
    });

    OpenApi.addSchema('SignupResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
        'user': {' \$ref': '#/components/schemas/AuthUser'},
        'org': {'\$ref': '#/components/schemas/AuthOrg'},
        'company': {'\$ref': '#/components/schemas/AuthCompany'},
      },
    });

    OpenApi.addSchema('LoginResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
        'user': {'\$ref': '#/components/schemas/AuthUser'},
        'org': {'\$ref': '#/components/schemas/AuthOrg'},
      },
    });

    OpenApi.addSchema('RefreshResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
      },
    });
  }

  // ===========================================================================
  // SWAGGER: SIGNUP
  // ===========================================================================
  void _registerSignupSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/signup',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Criação de conta (Org + Usuário)',
        description: 'Cria organização, usuário owner e empresa matriz.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {' \$ref': '#/components/schemas/SignupRequest'},
            },
          },
        ),
        responses: {
          '201': {
            'description': 'Conta criada com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
                'example': {
                  'success': true,
                  'message': 'Conta criada com sucesso',
                  'data': {
                    'access_token': 'jwt_access_here',
                    'refresh_token': 'jwt_refresh_here',
                    'access_expires_at': 1765504344,
                    'refresh_expires_at': 1766107344,
                    'user': {
                      'id': 'uuid',
                      'email': 'admin@empresa.com',
                      'full_name': 'Gabriel Lima',
                      'roles': ['owner'],
                    },
                    'org': {'id': 'uuid', 'name': 'Minha Empresa', 'slug': 'minha-empresa'},
                    'company': {'id': 'uuid', 'name': 'Matriz'},
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
  }

  // ===========================================================================
  // SWAGGER: LOGIN
  // ===========================================================================
  void _registerLoginSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/login',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Login',
        description: 'Autentica por email/senha e retorna tokens JWT.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/LoginRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Login realizado com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
                'example': {
                  'success': true,
                  'message': 'Login realizado com sucesso',
                  'data': {
                    'access_token': 'jwt_access_here',
                    'refresh_token': 'jwt_refresh_here',
                    'access_expires_at': 1765504344,
                    'refresh_expires_at': 1766107344,
                    'user': {
                      'id': 'uuid',
                      'email': 'admin@empresa.com',
                      'roles': ['owner'],
                    },
                    'org': {'id': 'uuid', 'name': 'Minha Empresa', 'slug': 'minha-empresa'},
                  },
                },
              },
            },
          },
          '401': {
            'description': 'Credenciais inválidas',
            'content': {
              'application/json': {
                'example': {'success': false, 'message': 'E-mail ou senha inválidos', 'data': null},
              },
            },
          },
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: REFRESH
  // ===========================================================================
  void _registerRefreshSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/refresh',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Renovar token de acesso',
        description: 'Gera novos tokens a partir de um refresh token válido.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/RefreshRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Token renovado com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
              },
            },
          },
          '401': {'description': 'Refresh token inválido/expirado'},
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: LOGOUT (revoga 1 refresh)
  // ===========================================================================
  void _registerLogoutSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout',
        description: 'Revoga o refresh token atual (body.refresh_token). Requer access token no Authorization.',
        security: const [
          {'BearerAuth': []},
        ],
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/LogoutRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Logout realizado com sucesso',
            'content': {
              'application/json': {
                'example': {'success': true, 'message': 'Logout realizado com sucesso', 'data': null},
              },
            },
          },
          '401': {'description': 'Token inválido ou revogado'},
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: LOGOUT ALL (revoga todos refresh do user)
  // ===========================================================================
  void _registerLogoutAllSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout-all',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout Global',
        description: 'Revoga todos os refresh tokens do usuário autenticado. Requer access token no Authorization.',
        security: const [
          {'BearerAuth': []},
        ],
        responses: {
          '200': {
            'description': 'Logout global realizado com sucesso',
            'content': {
              'application/json': {
                'example': {'success': true, 'message': 'Logout global realizado com sucesso', 'data': null},
              },
            },
          },
          '401': {'description': 'Token inválido ou revogado'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }
}


├── auth_service.dart:
import 'package:sympllizy_back/core/core.dart';

import 'auth_entity.dart';
import 'auth_repository.dart';

abstract class AuthService {
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName});
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<void> logoutAll({required String userId});
}

class AuthServiceImpl implements AuthService {
  final DatabaseConnection _db;
  final AuthRepository _repo;
  final JwtService _jwt;
  final PasswordHasher _hasher;
  final Logger _logger;

  AuthServiceImpl(this._repo, this._db, this._jwt, this._hasher, this._logger);

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

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final user = await _repo.findUserByEmail(email);
    if (user == null) {
      throw UnauthorizedException('Credenciais inválidas');
    }

    final isValid = _hasher.verify(password, user['password_hash']);
    if (!isValid) {
      throw UnauthorizedException('Credenciais inválidas');
    }

    final userId = user['id'].toString();
    final org = await _repo.findPrimaryOrgByUser(userId);
    final orgId = org['id'].toString();
    final roles = await _repo.findUserRoles(userId, orgId);

    final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: roles);

    await _db.transaction((tx) async {
      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));
    });

    return {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'access_expires_at': tokens.accessExpiresAt,
      'refresh_expires_at': tokens.refreshExpiresAt,
      'user': {'id': userId, 'email': email, 'roles': roles},
      'org': {'id': orgId, 'name': org['name'], 'slug': org['slug']},
    };
  }

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    // 1️⃣ Verifica JWT
    final jwt = _jwt.verifyRefreshToken(refreshToken);

    final userId = _jwt.getUserId(jwt);
    final orgId = _jwt.getOrgId(jwt);

    if (userId.isEmpty || orgId.isEmpty) {
      throw UnauthorizedException('Token inválido');
    }

    // 2️⃣ Transação REAL
    return await _db.transaction((tx) async {
      final exists = await _repo.findRefreshToken(tx, userId: userId, token: refreshToken);

      if (!exists) {
        throw UnauthorizedException('Refresh token inválido ou revogado');
      }

      // 3️⃣ Gera novos tokens
      final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: const []);

      // 4️⃣ Revoga o antigo
      await _repo.revokeRefreshToken(tx, refreshToken);

      // 5️⃣ Salva o novo
      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));

      return {'access_token': tokens.accessToken, 'refresh_token': tokens.refreshToken, 'access_expires_at': tokens.accessExpiresAt, 'refresh_expires_at': tokens.refreshExpiresAt};
    });
  }

  @override
  Future<void> logout(String refreshToken) async {
    // 1️⃣ Verifica JWT
    final jwt = _jwt.verifyRefreshToken(refreshToken);

    final userId = _jwt.getUserId(jwt);
    if (userId.isEmpty) {
      throw UnauthorizedException('Token inválido');
    }

    // 2️⃣ Revoga dentro de transação
    await _db.transaction((tx) async {
      final exists = await _repo.findRefreshToken(tx, userId: userId, token: refreshToken);

      if (!exists) {
        throw UnauthorizedException('Refresh token inválido ou já revogado');
      }

      await _repo.revokeRefreshToken(tx, refreshToken);
    });
  }

  @override
  Future<void> logoutAll({required String userId}) async {
    await _db.transaction((tx) async {
      _logger.info('auth.logout.global', 'Logout global realizado', context: {'user_id': userId});

      await _repo.revokeAllRefreshTokens(tx, userId);
    });
  }
}

├── auth.dart:
export 'auth_controller.dart';
export 'auth_dependecy.dart';
export 'auth_entity.dart';
export 'auth_param.dart';
export 'auth_repository.dart';
export 'auth_routes.dart';
export 'auth_service.dart';

└── signup_request.dart:
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

└── modules.dart:

└── server
    └── server.dart:
import 'dart:io';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/modules/module_dependecy.dart';

Future<void> startServer({int port = 8080}) async {
  final router = Router();

  // ================= ERROR HANDLER =================
  router.setErrorHandler(errorMiddleware);

  // ================= DEPENDÊNCIAS =================
  final db = DB.instance;
  final logger = DbLogger(db);
  final jwtService = JwtService.createFromEnv();
  const hasher = PasswordHasher();

  // ================= MIDDLEWARES GLOBAIS =================
  router.use(loggerContextMiddleware(logger));
  router.use(requestLogger(logger));
  router.use(loggingMiddleware);
  router.use(corsMiddleware);
  router.use(orgContextMiddleware);

  // ================= MODULES =================
  registerModules(router: router, db: db, jwtService: jwtService, hasher: hasher, logger: logger);

  // ================= DOCS =================
  router.get('/openapi.json', openApiHandler);
  router.get('/docs', swaggerHandler);
  router.get('/docs/:rest', swaggerHandler);

  // ================= HEALTH =================
  router.get('/health', healthHandler);

  // ================= START =================
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HTTP server ouvindo em http://localhost:$port');

  await for (final req in server) {
    router.handle(req);
  }
}

/// ================= OPENAPI JSON =================
Future<void> openApiHandler(HttpContext ctx) async {
  ctx.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(OpenApi.json());

  await ctx.response.close();
}

/// ================= SWAGGER UI =================
Future<void> swaggerHandler(HttpContext ctx) async {
  final shelfReq = await httpToShelfRequest(ctx.request);
  final shelfRes = await SwaggerHandler.handler(shelfReq);
  await sendShelfResponse(ctx.response, shelfRes);
}

/// ================= HEALTH =================
Future<void> healthHandler(HttpContext ctx) async {
  sendJson(ctx, HttpStatus.ok, ApiResponse.success(message: 'ok', data: {'uptime': DateTime.now().toIso8601String()}));
}


├── pubspec.lock
├── pubspec.yaml:
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

├── README.md
└── test
    └── server_test.dart

20 directories, 82 files
