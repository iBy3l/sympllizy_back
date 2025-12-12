import '../database/database_connection.dart';
import 'log_entry.dart';
import 'log_level.dart';
import 'logger.dart';

class DbLogger implements Logger {
  final DatabaseConnection db;

  DbLogger(this.db);

  @override
  Future<void> log(LogEntry e) async {
    await db.execute(
      '''
      INSERT INTO data.logs (
        level, type, message, context,
        user_id, org_id,
        method, path, status_code,
        ip, user_agent
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [e.level.name, e.type, e.message, e.context, e.userId, e.orgId, e.method, e.path, e.statusCode, e.ip, e.userAgent],
    );
  }

  @override
  Future<void> info(String type, String message, {Map<String, dynamic>? ctx}) {
    return log(LogEntry(level: LogLevel.info, type: type, message: message, context: ctx));
  }

  @override
  Future<void> error(String type, String message, {Map<String, dynamic>? ctx}) {
    return log(LogEntry(level: LogLevel.error, type: type, message: message, context: ctx));
  }
}
