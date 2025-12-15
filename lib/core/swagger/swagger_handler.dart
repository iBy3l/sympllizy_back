import 'package:shelf/shelf.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import '../openapi/openapi.dart';

class SwaggerHandler {
  static Handler get handler => SwaggerUI(OpenApi.json(), title: 'Sympllizy API Docs', specType: SpecType.json, persistAuthorization: true).call;
}
