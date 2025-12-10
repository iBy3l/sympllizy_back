import 'dart:io';

import 'package:sympllizy_back/core/database/db.dart';
import 'package:sympllizy_back/core/database/postgres_connection.dart';
import 'package:sympllizy_back/core/env/env.dart';
import 'package:sympllizy_back/server/server.dart';

Future<void> main() async {
  print("CURRENT DIR: ${Directory.current.path}");
  print("FILES HERE:");
  Directory.current.listSync().forEach((f) => print(" - $f"));
  Env.load();

  final db = PostgresConnection(Env.get('DATABASE_URL'));
  await db.connect();
  DB.init(db);

  final port = int.parse(Env.get('PORT', fallback: '8080'));
  await startServer(port: port);
}
