import 'package:sympllizy_back/core/logging/log_entry.dart';

abstract class Logger {
  Future<void> log(LogEntry entry);

  Future<void> info(String type, String message, {Map<String, dynamic>? ctx});
  Future<void> error(String type, String message, {Map<String, dynamic>? ctx});
}
