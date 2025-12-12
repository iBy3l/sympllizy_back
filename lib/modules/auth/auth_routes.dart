import 'package:sympllizy_back/core/core.dart';

import 'auth_controller.dart';

class AuthRoutes {
  final AuthController controller;

  AuthRoutes(this.controller);

  void register(Router router) {
    OpenApi.addOperation(
      method: 'post',
      path: '/auth/signup',
      operation: OpenApiOperation(
        summary: 'Criação de conta (Org + Usuário)',
        description: 'Cria uma organização, um usuário proprietário (owner) e a empresa matriz.',
        requestBody: OpenApiRequestBody(
          required: true,

          content: {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'org_name': {'type': 'string', 'example': 'Minha Empresa'},
                  'email': {'type': 'string', 'example': 'admin@empresa.com'},
                  'password': {'type': 'string', 'example': 'senha123'},
                  'full_name': {'type': 'string', 'example': 'Gabriel Lima'},
                },
                'required': ['org_name', 'email', 'password'],
              },
            },
          },
        ),
        responses: {
          '201': {
            'description': 'Conta criada com sucesso',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'example': {
                    "success": true,
                    "message": "Conta criada com sucesso",
                    "data": {
                      "access_token": "jwt_access_here",
                      "refresh_token": "jwt_refresh_here",
                      "user": {
                        "id": "uuid",
                        "email": "admin@empresa.com",
                        "full_name": "Gabriel Lima",
                        "roles": ["owner"],
                      },
                      "org": {"id": "uuid", "name": "Minha Empresa", "slug": "minha-empresa"},
                      "company": {"id": "uuid", "name": "Matriz"},
                    },
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

    router.group('/auth', (r) {
      r.post('/signup', controller.signup);
    });
  }
}
