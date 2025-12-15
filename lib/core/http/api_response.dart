class ApiResponse {
  static Map<String, dynamic> success({String message = 'OK', dynamic data}) {
    return {'success': true, 'message': message, 'data': data};
  }

  static Map<String, dynamic> error({required String message, String? code, dynamic data}) {
    return {'success': false, 'message': message, if (code != null) 'code': code, 'data': data};
  }
}
