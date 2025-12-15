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
    return {
      'summary': summary,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
      if (requestBody != null) 'requestBody': requestBody!.toJson(),
      'responses': responses,
      if (security != null) 'security': security,
    };
  }
}

class OpenApiRequestBody {
  final bool required;
  final Map<String, dynamic> content;

  OpenApiRequestBody({this.required = false, required this.content});

  Map<String, dynamic> toJson() => {'required': required, 'content': content};
}

class OpenApi {
  static final Map<String, dynamic> _paths = {};
  static final Map<String, dynamic> _schemas = {};
  static final Map<String, dynamic> _securitySchemes = {};
  static final List<Map<String, dynamic>> _tags = [];
  static final List<Map<String, dynamic>> _servers = [];
  static List<Map<String, List<String>>> _globalSecurity = [];

  // ---------------- SERVERS ----------------
  static void addServer({required String url, String? description}) {
    _servers.add({'url': url, if (description != null) 'description': description});
  }

  // ---------------- TAGS ----------------
  static void addTag({required String name, String? description}) {
    _tags.add({'name': name, if (description != null) 'description': description});
  }

  // ---------------- SCHEMAS ----------------
  static void addSchema(String name, Map<String, dynamic> schema) {
    _schemas[name] = schema;
  }

  // ---------------- SECURITY ----------------
  static void addSecurityScheme(String name, Map<String, dynamic> scheme) {
    _securitySchemes[name] = scheme;
  }

  static void setGlobalSecurity(List<Map<String, List<String>>> security) {
    _globalSecurity = security;
  }

  // ---------------- PATHS ----------------
  static void addOperation({required String method, required String path, required OpenApiOperation operation}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final lowerMethod = method.toLowerCase();

    _paths.putIfAbsent(normalizedPath, () => {});
    _paths[normalizedPath][lowerMethod] = operation.toJson();
  }

  // ---------------- JSON FINAL ----------------
  static String json() {
    return jsonEncode({
      'openapi': '3.0.0',
      'info': {'title': 'Sympllizy API', 'version': '1.0.0', 'description': 'API oficial da plataforma Sympllizy'},
      if (_servers.isNotEmpty) 'servers': _servers,
      if (_tags.isNotEmpty) 'tags': _tags,
      'paths': _paths,
      'components': {if (_schemas.isNotEmpty) 'schemas': _schemas, if (_securitySchemes.isNotEmpty) 'securitySchemes': _securitySchemes},
      if (_globalSecurity.isNotEmpty) 'security': _globalSecurity,
    });
  }
}
