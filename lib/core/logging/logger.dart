import 'package:sympllizy_back/core/logging/log_entry.dart';

import 'log_level.dart';

abstract class Logger {
  Future<void> log(LogEntry entry);

  Future<void> info(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.info, type: type, message: message, context: context));
  }

  Future<void> error(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.error, type: type, message: message, context: context));
  }

  Future<void> warning(String type, String message, {Map<String, dynamic>? context}) {
    return log(LogEntry(level: LogLevel.warn, type: type, message: message, context: context));
  }
}
