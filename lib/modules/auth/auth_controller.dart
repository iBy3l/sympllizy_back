import 'dart:developer';

import 'package:sympllizy_back/core/core.dart';

import 'auth_service.dart';

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  Future<void> signup(HttpContext ctx) async {
    try {
      final body = await ctx.bodyAsJson();

      final orgName = body['org_name'];
      final email = body['email'];
      final password = body['password'];
      final fullName = body['full_name'];

      if (orgName == null || email == null || password == null) {
        throw ValidationException(
          'Dados inválidos',
          details: {
            'required': ['org_name', 'email', 'password'],
          },
        );
      }

      final entity = await _service.signup(orgName: orgName, email: email, password: password, fullName: fullName);

      // 👇 AQUI está a correção principal: usamos toMap()
      sendJson(ctx, 201, ApiResponse.success(message: "Conta criada com sucesso", data: entity.toMap()));
    } on ValidationException catch (e) {
      sendJson(ctx, 400, ApiResponse.error(message: e.message, data: e.details));
    } catch (e, stack) {
      log("Erro em signup", error: e, stackTrace: stack);
      sendJson(ctx, 500, ApiResponse.error(message: "Erro interno"));
    }
  }
}
