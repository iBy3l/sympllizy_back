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
