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
