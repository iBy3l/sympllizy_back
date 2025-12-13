import 'package:sympllizy_back/core/openapi/openapi.dart';

void registerBearerAuth() {
  OpenApi.addSecurityScheme('BearerAuth', {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT', 'description': 'Informe o token JWT no formato: Bearer {token}'});
}
