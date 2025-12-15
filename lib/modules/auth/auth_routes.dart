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

      r.post('/logout', chain([jwtMiddleware(jwtService), requireAuth()], controller.logout));

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
  // SCHEMAS
  // ===========================================================================
  void _registerSchemas() {
    // ---------- REQUESTS ----------
    OpenApi.addSchema('SignupRequest', {
      'type': 'object',
      'required': ['org_name', 'email', 'password'],
      'properties': {
        'org_name': {'type': 'string', 'example': 'Minha Empresa'},
        'email': {'type': 'string', 'format': 'email', 'example': 'admin@empresa.com'},
        'password': {'type': 'string', 'format': 'password', 'example': 'senha123'},
        'full_name': {'type': 'string', 'nullable': true, 'example': 'Gabriel Lima'},
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

    // ---------- ENTITIES ----------
    OpenApi.addSchema('AuthUser', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid'},
        'email': {'type': 'string'},
        'full_name': {'type': 'string', 'nullable': true},
        'roles': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    });

    OpenApi.addSchema('AuthOrg', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid'},
        'name': {'type': 'string'},
        'slug': {'type': 'string'},
      },
    });

    OpenApi.addSchema('AuthCompany', {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'format': 'uuid'},
        'name': {'type': 'string'},
      },
    });

    // ---------- TOKENS ----------
    OpenApi.addSchema('TokenPair', {
      'type': 'object',
      'properties': {
        'access_token': {'type': 'string'},
        'refresh_token': {'type': 'string'},
        'access_expires_at': {'type': 'integer'},
        'refresh_expires_at': {'type': 'integer'},
      },
    });

    // ---------- RESPONSE DATA ----------
    OpenApi.addSchema('SignupResponseData', {
      'allOf': [
        {r'$ref': '#/components/schemas/TokenPair'},
        {
          'type': 'object',
          'properties': {
            'user': {r'$ref': '#/components/schemas/AuthUser'},
            'org': {r'$ref': '#/components/schemas/AuthOrg'},
            'company': {r'$ref': '#/components/schemas/AuthCompany'},
          },
        },
      ],
    });

    OpenApi.addSchema('LoginResponseData', {
      'allOf': [
        {r'$ref': '#/components/schemas/TokenPair'},
        {
          'type': 'object',
          'properties': {
            'user': {r'$ref': '#/components/schemas/AuthUser'},
            'org': {r'$ref': '#/components/schemas/AuthOrg'},
          },
        },
      ],
    });

    OpenApi.addSchema('RefreshResponseData', {r'$ref': '#/components/schemas/TokenPair'});

    // ---------- API RESPONSES ----------
    OpenApi.addSchema('ApiResponseSignup', {
      'type': 'object',
      'properties': {
        'success': {'type': 'boolean'},
        'message': {'type': 'string'},
        'data': {r'$ref': '#/components/schemas/SignupResponseData'},
      },
    });

    OpenApi.addSchema('ApiResponseLogin', {
      'type': 'object',
      'properties': {
        'success': {'type': 'boolean'},
        'message': {'type': 'string'},
        'data': {r'$ref': '#/components/schemas/LoginResponseData'},
      },
    });

    OpenApi.addSchema('ApiResponseRefresh', {
      'type': 'object',
      'properties': {
        'success': {'type': 'boolean'},
        'message': {'type': 'string'},
        'data': {r'$ref': '#/components/schemas/RefreshResponseData'},
      },
    });
  }

  // ===========================================================================
  // OPERATIONS
  // ===========================================================================
  void _registerSignupSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/signup',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Criação de conta',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/SignupRequest'},
            },
          },
        ),
        responses: {
          '201': {
            'description': 'Conta criada com sucesso',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/ApiResponseSignup'},
              },
            },
          },
        },
      ),
    );
  }

  void _registerLoginSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/login',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Login',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/LoginRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Login realizado',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/ApiResponseLogin'},
              },
            },
          },
        },
      ),
    );
  }

  void _registerRefreshSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/refresh',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Refresh token',
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/RefreshRequest'},
            },
          },
        ),
        responses: {
          '200': {
            'description': 'Token renovado',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/ApiResponseRefresh'},
              },
            },
          },
        },
      ),
    );
  }

  void _registerLogoutSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout',
        security: const [
          {'BearerAuth': []},
        ],
        requestBody: OpenApiRequestBody(
          required: true,
          content: {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/LogoutRequest'},
            },
          },
        ),
        responses: {
          '200': {'description': 'Logout realizado'},
        },
      ),
    );
  }

  void _registerLogoutAllSwagger() {
    OpenApi.addOperation(
      method: 'post',
      path: '$_base/logout-all',
      operation: OpenApiOperation(
        tags: const ['Auth'],
        summary: 'Logout global',
        security: const [
          {'BearerAuth': []},
        ],
        responses: {
          '200': {'description': 'Logout global realizado'},
        },
      ),
    );
  }
}
