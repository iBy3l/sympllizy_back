class AuthParam {
  final String email;
  final String password;
  final String fullName;
  final String orgName;
  AuthParam({required this.email, required this.password, required this.fullName, required this.orgName});

  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password, 'full_name': fullName, 'org_name': orgName};
  }
}
