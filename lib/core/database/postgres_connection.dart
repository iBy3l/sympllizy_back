import 'package:postgres/postgres.dart';

import 'database_connection.dart';

class PostgresConnection extends DatabaseConnection {
  final String url;
  Connection? _conn;

  PostgresConnection(this.url);

  @override
  Future<void> connect() async {
    final uri = Uri.parse(url);

    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':')[1] : null,
    );

    _conn = await Connection.open(endpoint, settings: const ConnectionSettings(sslMode: SslMode.disable));

    print('[DB] Conectado com sucesso!');
  }

  Connection get raw => _conn!;

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    final conn = _conn!;
    final result = await conn.execute(sql, parameters: params);

    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    final conn = _conn!;
    final result = await conn.execute(sql, parameters: params);

    return result.affectedRows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action) async {
    final conn = _conn!;
    return await conn.runTx((session) async {
      final txConn = _TxPostgresConnection(session);
      return await action(txConn);
    });
  }
}

/// Conexão usada **dentro** de uma transação
class _TxPostgresConnection extends DatabaseConnection {
  final Session _session;

  _TxPostgresConnection(this._session);

  @override
  Future<void> connect() async {
    // Não faz nada em tx
    return;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    final result = await _session.execute(sql, parameters: params);

    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    final result = await _session.execute(sql, parameters: params);
    return result.affectedRows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection tx) action) {
    throw UnsupportedError('Transação dentro de transação não suportada');
  }
}
