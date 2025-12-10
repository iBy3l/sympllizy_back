import 'package:postgres/postgres.dart';
import 'package:sympllizy_back/core/database/database_connection.dart';

class PostgresConnection extends DatabaseConnection {
  final String url;
  late final Endpoint _endpoint;

  Connection? _conn;

  PostgresConnection(this.url) {
    final uri = Uri.parse(url);

    _endpoint = Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '',
    );
  }

  @override
  Future<void> connect() async {
    _conn = await Connection.open(
      _endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.disable, // LOCAL => sem SSL
      ),
    );

    print('[DB] Conectado com sucesso!');
  }

  Connection get raw => _conn!;

  // --------------------------
  // QUERY
  // --------------------------
  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    if (_conn == null) throw Exception('DB não conectado');

    final result = await _conn!.execute(sql, parameters: params ?? const []);

    return result.map((row) => row.toColumnMap()).toList();
  }

  // --------------------------
  // EXECUTE (INSERT/UPDATE/DELETE)
  // --------------------------
  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    if (_conn == null) throw Exception('DB não conectado');

    final result = await _conn!.execute(sql, parameters: params ?? const []);

    return result.affectedRows;
  }

  // --------------------------
  // TRANSACTION
  // --------------------------
  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    if (_conn == null) throw Exception('DB não conectado');

    return await _conn!.runTx((session) async {
      try {
        final value = await action();
        return value;
      } catch (e) {
        await session.rollback();
        rethrow;
      }
    });
  }
}
