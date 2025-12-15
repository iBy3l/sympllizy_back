import 'package:sympllizy_back/core/errors/unauthorized_exception.dart';

import 'context.dart';

class AuthContext {
  final String userId;
  final String orgId;
  final List<String> roles;

  AuthContext({required this.userId, required this.orgId, required this.roles});
}

extension HttpContextAuth on HttpContext {
  static const _key = '_auth';

  AuthContext get auth {
    final value = items[_key];
    if (value is! AuthContext) {
      throw UnauthorizedException('Usuário não autenticado');
    }
    return value;
  }

  bool get isAuthenticated => items.containsKey(_key);

  void setAuth(AuthContext auth) {
    items[_key] = auth;
  }
}
