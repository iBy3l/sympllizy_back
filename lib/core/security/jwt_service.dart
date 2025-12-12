// lib/core/security/jwt_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sympllizy_back/core/security/token_pair.dart';

import '../env/env.dart';

class JwtService {
  final String _secret;
  final String _issuer;

  final Duration accessTokenDuration;
  final Duration refreshTokenDuration;

  JwtService({String? secret, String? issuer, this.accessTokenDuration = const Duration(minutes: 30), this.refreshTokenDuration = const Duration(days: 7)})
    : _secret = secret ?? Env.get('JWT_SECRET'),
      _issuer = issuer ?? Env.get('JWT_ISSUER');

  TokenPair generateTokens({required String userId, required String orgId, List<String> roles = const []}) {
    final now = DateTime.now();
    final accessExp = now.add(accessTokenDuration);
    final refreshExp = now.add(refreshTokenDuration);
    // ACCESS TOKEN --------------------------------------------------------
    final accessJwt = JWT(
      {'org': orgId, 'roles': roles, 'type': 'access', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': accessExp.millisecondsSinceEpoch ~/ 1000},
      issuer: _issuer,
      subject: userId,
    );
    final accessToken = accessJwt.sign(SecretKey(_secret));
    // REF
    // REF
    // REFRESH TOKEN --------------------------------------------------------
    final refreshJwt = JWT({'org': orgId, 'type': 'refresh', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': refreshExp.millisecondsSinceEpoch ~/ 1000}, issuer: _issuer, subject: userId);
    final refreshToken = refreshJwt.sign(SecretKey(_secret));
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken, accessExpiresAt: accessExp.millisecondsSinceEpoch ~/ 1000, refreshExpiresAt: refreshExp.millisecondsSinceEpoch ~/ 1000);
  }

  TokenPair generateTokenPair({required String userId, required String orgId, List<String> roles = const []}) {
    final now = DateTime.now();
    final accessExp = now.add(accessTokenDuration);
    final refreshExp = now.add(refreshTokenDuration);

    // ACCESS TOKEN --------------------------------------------------------
    final accessJwt = JWT(
      {'org': orgId, 'roles': roles, 'type': 'access', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': accessExp.millisecondsSinceEpoch ~/ 1000},
      issuer: _issuer,
      subject: userId,
    );

    final accessToken = accessJwt.sign(SecretKey(_secret));

    // REFRESH TOKEN --------------------------------------------------------
    final refreshJwt = JWT({'org': orgId, 'type': 'refresh', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': refreshExp.millisecondsSinceEpoch ~/ 1000}, issuer: _issuer, subject: userId);

    final refreshToken = refreshJwt.sign(SecretKey(_secret));

    return TokenPair(accessToken: accessToken, refreshToken: refreshToken, accessExpiresAt: accessExp.millisecondsSinceEpoch ~/ 1000, refreshExpiresAt: refreshExp.millisecondsSinceEpoch ~/ 1000);
  }

  // -----------------------------------------------------------------------
  static JwtService createFromEnv() => JwtService();
  JWT verifyAccessToken(String token) {
    final jwt = _verify(token);
    if (jwt.payload['type'] != 'access') {
      throw JWTException('Invalid token type');
    }
    return jwt;
  }

  JWT verifyRefreshToken(String token) {
    final jwt = _verify(token);
    if (jwt.payload['type'] != 'refresh') {
      throw JWTException('Invalid token type');
    }
    return jwt;
  }

  JWT _verify(String token) {
    try {
      return JWT.verify(token, SecretKey(_secret));
    } on JWTExpiredException {
      throw JWTException('Token expired');
    } on JWTException catch (e) {
      throw JWTException(e.message);
    }
  }

  String getUserId(JWT jwt) => jwt.subject ?? '';

  String getOrgId(JWT jwt) => jwt.payload['org'] as String? ?? '';

  List<String> getRoles(JWT jwt) {
    final roles = jwt.payload['roles'];
    if (roles is List) {
      return roles.whereType<String>().toList();
    }
    return [];
  }
}
