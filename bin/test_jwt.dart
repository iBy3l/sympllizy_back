import 'package:sympllizy_back/core/security/jwt_service.dart';

void main() {
  final jwtService = JwtService(secret: 'minha_chave_super_secreta', issuer: 'sympllizy-backend');

  print('--- GERANDO TOKENS ---');

  final tokens = jwtService.generateTokenPair(userId: 'user-123', orgId: 'org-abc', roles: ['admin']);

  print('\nACCESS TOKEN:\n${tokens.accessToken}');
  print('\nREFRESH TOKEN:\n${tokens.refreshToken}');

  print('\n--- VALIDANDO ACCESS TOKEN ---');

  try {
    final jwt = jwtService.verifyAccessToken(tokens.accessToken);

    print('Token válido.');
    print('User ID: ${jwtService.getUserId(jwt)}');
    print('Org ID: ${jwtService.getOrgId(jwt)}');
    print('Roles: ${jwtService.getRoles(jwt)}');
    print('Payload completo: ${jwt.payload}');
  } catch (e) {
    print('ERRO VALIDANDO ACCESS: $e');
  }

  print('\n--- VALIDANDO REFRESH TOKEN ---');

  try {
    final jwt = jwtService.verifyRefreshToken(tokens.refreshToken);

    print('Refresh válido.');
    print('User ID: ${jwtService.getUserId(jwt)}');
    print('Org ID: ${jwtService.getOrgId(jwt)}');
    print('Payload completo: ${jwt.payload}');
  } catch (e) {
    print('ERRO VALIDANDO REFRESH: $e');
  }
}
