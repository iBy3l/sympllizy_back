import 'package:sympllizy_back/core/core.dart';

import 'auth_controller.dart';

class AuthRoutes {
  final AuthController controller;
  final JwtService jwtService;

  AuthRoutes(this.controller, this.jwtService);

  static const String _base = '/v1/auth';

  void register(Router router) {
    // =======================
    // ROTAS (VERSIONADAS)
    // =======================
    router.group(_base, (r) {
      r.post('/signup', controller.signup);
      r.post('/login', controller.login);
      r.post('/refresh', controller.refresh);

      // 🔐 precisa JWT (access) + body(refresh_token)
      r.post('/logout', chain([jwtMiddleware(jwtService), requireAuth()], controller.logout));

      // 🔐 precisa JWT (access)
      r.post('/logout-all', chain([jwtMiddleware(jwtService), requireAuth()], controller.logoutAll));
    });

    // =======================
    // SWAGGER
    // =======================
    _registerSchemas();
    _registerSignupSwagger();
    _registerLoginSwagger();
    _registerRefreshSwagger();
    _registerLogoutSwagger();
    _registerLogoutAllSwagger();
  }

  // ===========================================================================
  // SCHEMAS (reutilizáveis)
  // ===========================================================================
  void _registerSchemas() {
    // Requests
    OpenApi.addSchema('SignupRequest', {
      'type': 'object',
      'required': ['org_name', 'email', 'password'],
      'properties': {
        'org_name': {'type': 'string', 'example': 'Minha Empresa'},
        'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
        'password': {'type': 'string', 'format': 'password', 'example': 'senha123'},
        'full_name': {'type': 'string', 'example': 'Gabriel Lima'},
      },
    });

    OpenApi.addSchema('LoginRequest', {
      'type': 'object',
      'required': ['email', 'password'],
      'properties': {
        'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
        'password': {'type': 'string', 'format': 'password', 'example': '123456'},
      },
    });

    OpenApi.addSchema('RefreshRequest', {
      'type': 'object',
      'required': ['refresh_token'],
      'properties': {
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
      },
    });

    OpenApi.addSchema('LogoutRequest', {
      'type': 'object',
      'required': ['refresh_token'],
      'properties': {
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
      },
    });

    // Responses (data payloads)
    OpenApi.addSchema('AuthUser', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': '06a76be0-cabc-44c0-989d-fbfbd7c95ad1'},
        'email': {'type': 'string', 'example': 'admin@empresa.com'},
        'full_name': {'type': 'string', 'nullable': true, 'example': 'Gabriel Lima'},
        'roles': {
          'type': 'array',
          'items': {'type': 'string'},
          'example': ['owner'],
        },
      },
    });

    OpenApi.addSchema('AuthOrg', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': 'e9b73189-f499-4369-877a-3cf4526bfb8d'},
        'name': {'type': 'string', 'example': 'Minha Empresa'},
        'slug': {'type': 'string', 'example': 'minha-empresa'},
      },
    });

    OpenApi.addSchema('AuthCompany', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid', 'example': '9692927d-9af6-4601-9437-832999028d26'},
        'name': {'type': 'string', 'example': 'Matriz'},
      },
    });

    OpenApi.addSchema('TokenPair', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string', 'example': 'jwt_access_here'},
        'refresh_token': {'type': 'string', 'example': 'jwt_refresh_here'},
        'access_expires_at': {'type': 'integer', 'example': 1765504344},
        'refresh_expires_at': {'type': 'integer', 'example': 1766107344},
      },
    });

    OpenApi.addSchema('SignupResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
        'user': {' \$ref': '#/components/schemas/AuthUser'},
        'org': {'\$ref': '#/components/schemas/AuthOrg'},
        'company': {'\$ref': '#/components/schemas/AuthCompany'},
      },
    });

    OpenApi.addSchema('LoginResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
        'user': {'\$ref': '#/components/schemas/AuthUser'},
        'org': {'\$ref': '#/components/schemas/AuthOrg'},
      },
    });

    OpenApi.addSchema('RefreshResponseData', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
      },
    });
  }

  // ===========================================================================
  // SWAGGER: SIGNUP
  // ===========================================================================
  void _registerSignupSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/signup',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Criação de conta (Org + Usuário)',
        description: 'Cria organização, usuário owner e empresa matriz.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {' \$ref': '#/components/schemas/SignupRequest'},
            },
          },
        ),
        responses: {
          '201': {
            'description': 'Conta criada com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
                'example': {
                  'success': true,
                  'message': 'Conta criada com sucesso',
                  'data': {
                    'access_token': 'jwt_access_here',
                    'refresh_token': 'jwt_refresh_here',
                    'access_expires_at': 1765504344,
                    'refresh_expires_at': 1766107344,
                    'user': {
                      'id': 'uuid',
                      'email': 'admin@empresa.com',
                      'full_name': 'Gabriel Lima',
                      'roles': ['owner'],
                    },
                    'org': {'id': 'uuid', 'name': 'Minha Empresa', 'slug': 'minha-empresa'},
                    'company': {'id': 'uuid', 'name': 'Matriz'},
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

  // ===========================================================================
  // SWAGGER: LOGIN
  // ===========================================================================
  void _registerLoginSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/login',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Login',
        description: 'Autentica por email/senha e retorna tokens JWT.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/LoginRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Login realizado com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
                'example': {
                  'success': true,
                  'message': 'Login realizado com sucesso',
                  'data': {
                    'access_token': 'jwt_access_here',
                    'refresh_token': 'jwt_refresh_here',
                    'access_expires_at': 1765504344,
                    'refresh_expires_at': 1766107344,
                    'user': {
                      'id': 'uuid',
                      'email': 'admin@empresa.com',
                      'roles': ['owner'],
                    },
                    'org': {'id': 'uuid', 'name': 'Minha Empresa', 'slug': 'minha-empresa'},
                  },
                },
              },
            },
          },
          '401': {
            'description': 'Credenciais inválidas',
            'content': {
              'application/json': {
                'example': {'success': false, 'message': 'E-mail ou senha inválidos', 'data': null},
              },
            },
          },
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: REFRESH
  // ===========================================================================
  void _registerRefreshSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/refresh',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Renovar token de acesso',
        description: 'Gera novos tokens a partir de um refresh token válido.',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/RefreshRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Token renovado com sucesso',
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ApiResponse'},
              },
            },
          },
          '401': {'description': 'Refresh token inválido/expirado'},
          '400': {'description': 'Erro de validação'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: LOGOUT (revoga 1 refresh)
  // ===========================================================================
  void _registerLogoutSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout',
        description: 'Revoga o refresh token atual (body.refresh_token). Requer access token no Authorization.',
        security: const [
          {'BearerAuth': []},
        ],
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {'\$ref': '#/components/schemas/LogoutRequest'},
            },
          },
        ),
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
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }

  // ===========================================================================
  // SWAGGER: LOGOUT ALL (revoga todos refresh do user)
  // ===========================================================================
  void _registerLogoutAllSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout-all',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout Global',
        description: 'Revoga todos os refresh tokens do usuário autenticado. Requer access token no Authorization.',
        security: const [
          {'BearerAuth': []},
        ],
        responses: {
          '200': {
            'description': 'Logout global realizado com sucesso',
            'content': {
              'application/json': {
                'example': {'success': true, 'message': 'Logout global realizado com sucesso', 'data': null},
              },
            },
          },
          '401': {'description': 'Token inválido ou revogado'},
          '500': {'description': 'Erro interno do servidor'},
        },
      ),
    );
  }
}
