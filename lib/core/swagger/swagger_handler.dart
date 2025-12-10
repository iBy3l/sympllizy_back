import 'package:shelf/shelf.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import 'openapi_spec.dart';

class SwaggerHandler {
  static Handler get handler => SwaggerUI(OpenApiSpec.spec, title: 'Sympllizy API Docs', specType: SpecType.json, docExpansion: DocExpansion.list, deepLink: true, persistAuthorization: true).call;
}
