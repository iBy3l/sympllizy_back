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
