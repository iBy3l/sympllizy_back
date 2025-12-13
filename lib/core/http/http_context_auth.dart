import 'context.dart';

class AuthContext {
  final String userId;
  final String orgId;
  final List<String> roles;

  AuthContext({required this.userId, required this.orgId, required this.roles});
}

extension AuthContextExt on HttpContext {
  static const _key = '_auth';

  /// Retorna o contexto autenticado ou null
  AuthContext? get auth => locals[_key] as AuthContext?;

  /// Apenas verifica se existe auth no contexto
  bool get isAuthenticated => locals.containsKey(_key);

  /// Usado pelo jwtMiddleware
  void setAuth(AuthContext auth) {
    locals[_key] = auth;
  }
}
