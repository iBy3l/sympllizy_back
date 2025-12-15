class AuthPayload {
  final String userId;
  final String orgId;
  final List<String> roles;

  AuthPayload({required this.userId, required this.orgId, required this.roles});
}
