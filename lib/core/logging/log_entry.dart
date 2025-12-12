import 'log_level.dart';

class LogEntry {
  final LogLevel level;
  final String type;
  final String message;

  final Map<String, dynamic>? context;

  final String? userId;
  final String? orgId;

  final String? method;
  final String? path;
  final int? statusCode;

  final String? ip;
  final String? userAgent;

  final String? requestId;

  LogEntry({required this.level, required this.type, required this.message, this.context, this.userId, this.orgId, this.method, this.path, this.statusCode, this.ip, this.userAgent, this.requestId});
}
