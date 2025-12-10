class ApiResponse {
  static Map<String, dynamic> success({String message = 'OK', dynamic data}) {
    return {'success': true, 'message': message, 'data': data};
  }

  static Map<String, dynamic> error({String message = 'Erro', dynamic data}) {
    return {'success': false, 'message': message, 'data': data};
  }
}
