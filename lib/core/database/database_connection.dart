abstract class DatabaseConnection {
  Future<void> connect();

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic> params]);

  Future<int> execute(String sql, [List<dynamic> params]);

  Future<T> transaction<T>(Future<T> Function() action);
}
