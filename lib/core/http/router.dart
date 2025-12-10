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
