import 'dart:convert';

import '../database/database_connection.dart';
import 'log_entry.dart';
import 'logger.dart';

class DbLogger extends Logger {
  final DatabaseConnection db;

  DbLogger(this.db);
  @override
  Future<void> log(LogEntry entry) async {
    await db.execute(
      '''
      INSERT INTO data.logs (
        level,
        type,
        message,
        context,
        request_id,
        method,
        path,
        status_code,
        user_id,
        org_id,
        ip,
        user_agent,
        created_at
      )
      VALUES (
        \$1, \$2, \$3, \$4,
        \$5, \$6, \$7, \$8,
        \$9, \$10, \$11, \$12,
        NOW()
      )
      ''',
      [
        entry.level.name,
        entry.type,
        entry.message,
        entry.context != null ? jsonEncode(entry.context) : null,
        entry.requestId,
        entry.method,
        entry.path,
        entry.statusCode,
        entry.userId,
        entry.orgId,
        entry.ip,
        entry.userAgent,
      ],
    );
  }
}
