import 'package:sympllizy_back/core/database/database_connection.dart';

class DB {
  static late final DatabaseConnection _instance;

  DB._();

  static void init(DatabaseConnection connection) {
    _instance = connection;
  }

  static DatabaseConnection get instance => _instance;
}
