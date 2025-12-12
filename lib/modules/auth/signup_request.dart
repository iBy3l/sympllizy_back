class SignupRequest {
  final String orgName;
  final String email;
  final String password;
  final String? fullName;

  SignupRequest({required this.orgName, required this.email, required this.password, this.fullName});

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(orgName: json['org_name'], email: json['email'], password: json['password'], fullName: json['full_name']);
  }
}
