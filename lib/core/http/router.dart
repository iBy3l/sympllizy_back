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
