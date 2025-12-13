import 'package:sympllizy_back/core/core.dart';

import 'auth_controller.dart';

class AuthRoutes {
  final AuthController controller;
  final JwtService jwtService;

  AuthRoutes(this.controller, this.jwtService);

  void register(Router router) {
    // =======================
    // ROTAS
    // =======================
    router.group('/auth', (r) {
      r.post('/signup', controller.signup);
      r.post('/login', controller.login);
      r.post('/refresh', controller.refresh);
      r.post('/logout', chain([jwtMiddleware(jwtService), requireAuth()], controller.logout));
    });

    // =======================
    // SWAGGER
    // =======================
    _registerSignupSwagger();
    _registerLoginSwagger();
    _registerRefreshSwagger();
    _registerLogoutSwagger();
  }

  void _registerLogoutSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '/auth/logout',
      operation: OpenApiOperation(
        summary: 'Logout',
        description: 'Revoga o refresh token atual',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {
                'type': 'object',
                'required': ['refresh_token'],
                'properties': {
                  'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
                },
              },
            },
          },
        ),
        security: [
          {'bearerAuth': []},
        ],
        responses: {
          '200': {
            'description': 'Logout realizado com sucesso',
            'content': {
              'application/json': {
                'example': {'success': true, 'message': 'Logout realizado com sucesso', 'data': null},
              },
            },
          },
          '401': {'description': 'Token inválido ou revogado'},
          '400': {'description': 'Erro de validação'},
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIGNUP
  // ---------------------------------------------------------------------------
  void _registerSignupSwagger() {
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
                'required': ['org_name', 'email', 'password'],
                'properties': {
                  'org_name': {'type': 'string', 'example': 'Minha Empresa'},
                  'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
                  'password': {'type': 'string', 'format': 'password', 'example': 'senha123'},
                  'full_name': {'type': 'string', 'example': 'Gabriel Lima'},
                },
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
                      "access_expires_at": 1765504344,
                      "refresh_expires_at": 1766107344,
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
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  void _registerLoginSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '/auth/login',
      operation: OpenApiOperation(
        summary: 'Login',
        description: 'Autentica o usuário usando e-mail e senha e retorna os tokens JWT.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {
                'type': 'object',
                'required': ['email', 'password'],
                'properties': {
                  'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
                  'password': {'type': 'string', 'format': 'password', 'example': '123456'},
                },
              },
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Login realizado com sucesso',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'example': {
                    "success": true,
                    "message": "Login realizado com sucesso",
                    "data": {
                      "access_token": "jwt_access_here",
                      "refresh_token": "jwt_refresh_here",
                      "access_expires_at": 1765504344,
                      "refresh_expires_at": 1766107344,
                      "user": {
                        "id": "uuid",
                        "email": "admin@empresa.com",
                        "full_name": "Gabriel Lima",
                        "roles": ["owner"],
                      },
                      "org": {"id": "uuid", "name": "Minha Empresa", "slug": "minha-empresa"},
                    },
                  },
                },
              },
            },
          },
          '401': {
            'description': 'Credenciais inválidas',
            'content': {
              'application/json': {
                'example': {"success": false, "message": "E-mail ou senha inválidos", "data": null},
              },
            },
          },
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  void _registerRefreshSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '/auth/refresh',
      operation: OpenApiOperation(
        summary: 'Renovar token de acesso',
        description: 'Gera um novo access_token e refresh_token a partir de um refresh token válido.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {
                'type': 'object',
                'required': ['refresh_token'],
                'properties': {
                  'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
                },
              },
            },
          },
        ),
        responses: {
          '200': {'description': 'Token renovado com sucesso'},
          '401': {'description': 'Refresh token inválido ou expirado'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }
}
