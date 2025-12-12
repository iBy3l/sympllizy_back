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
