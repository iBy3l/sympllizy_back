// lib/core/security/token_pair.dart
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int accessExpiresAt;
  final int refreshExpiresAt;

  const TokenPair({required this.accessToken, required this.refreshToken, required this.accessExpiresAt, required this.refreshExpiresAt});
}
