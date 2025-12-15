import 'openapi.dart';

void bootstrapOpenApi() {
  // -------- SERVERS --------
  OpenApi.addServer(url: 'http://localhost:8080', description: 'Ambiente local');

  // -------- TAGS --------
  OpenApi.addTag(name: 'Auth', description: 'Autenticação e sessão');
  OpenApi.addTag(name: 'Users', description: 'Usuário autenticado');
  OpenApi.addTag(name: 'Admin', description: 'Administração');
  OpenApi.addTag(name: 'System', description: 'Sistema');

  // -------- SECURITY --------
  OpenApi.addSecurityScheme('BearerAuth', {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT'});

  OpenApi.setGlobalSecurity([
    {'BearerAuth': []},
  ]);

  // -------- SCHEMAS BASE --------
  OpenApi.addSchema('ApiResponse', {
    'type': 'object',
    'required': ['success', 'message'],
    'properties': {
      'success': {'type': 'boolean'},
      'message': {'type': 'string'},
      'data': {'nullable': true},
    },
  });

  OpenApi.addSchema('ErrorResponse', {
    'type': 'object',
    'required': ['success', 'message', 'code'],
    'properties': {
      'success': {'type': 'boolean', 'example': false},
      'message': {'type': 'string', 'example': 'Token inválido ou expirado'},
      'code': {'type': 'string', 'example': 'UNAUTHORIZED'},
      'data': {
        'nullable': true,
        'description': 'Detalhes adicionais do erro (opcional)',
        'example': {'field': 'email'},
      },
    },
  });
}
