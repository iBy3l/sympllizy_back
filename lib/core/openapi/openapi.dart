import 'dart:convert';

class OpenApiOperation {
  final String summary;
  final Map<String, dynamic>? requestBodySchema;
  final Map<String, dynamic>? responses;

  OpenApiOperation({required this.summary, this.requestBodySchema, this.responses});

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      if (requestBodySchema != null)
        'requestBody': {
          'content': {
            'application/json': {'schema': requestBodySchema},
          },
        },
      if (responses != null) 'responses': responses,
    };
  }
}

class OpenApi {
  static final Map<String, Map<String, OpenApiOperation>> _paths = {};

  static void addOperation({
    required String method, // get, post...
    required String path, // /auth/signup
    required OpenApiOperation operation,
  }) {
    final m = method.toLowerCase();

    _paths.putIfAbsent(path, () => {});
    _paths[path]![m] = operation;
  }

  static Map<String, dynamic> build() {
    final paths = <String, dynamic>{};

    _paths.forEach((path, methods) {
      paths[path] = {for (final entry in methods.entries) entry.key: entry.value.toJson()};
    });

    return {
      'openapi': '3.0.3',
      'info': {'title': 'Sympllizy API', 'version': '1.0.0'},
      'paths': paths,
    };
  }

  static String json() => jsonEncode(build());
}
