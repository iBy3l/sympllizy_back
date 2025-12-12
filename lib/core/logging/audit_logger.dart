import '../core.dart';

class AuditLogger {
  final Logger logger;

  AuditLogger(this.logger);

  Future<void> log({required String action, required String entity, required String entityId, required HttpContext ctx, Map<String, dynamic>? changes}) {
    return logger.log(
      LogEntry(
        level: LogLevel.info,
        type: 'audit',
        message: '$action $entity',
        userId: ctx.locals['userId'],
        orgId: ctx.locals['orgId'],
        context: {'entity': entity, 'entity_id': entityId, 'changes': changes},
      ),
    );
  }
}
