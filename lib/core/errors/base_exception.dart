class BaseException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  BaseException(this.message, {this.statusCode = 400, this.code, this.details});

  @override
  String toString() => 'BaseException($statusCode, $code, $message)';
}
