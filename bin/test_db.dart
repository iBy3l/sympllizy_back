import 'dart:async';

import 'package:sympllizy_back/core/core.dart';
import 'package:sympllizy_back/core/env/env.dart';

Future<void> main() async {
  print("=== TESTE DE BANCO DE DADOS ===");

  Env.load();
  AppConfig.load();

  final db = PostgresConnection(Env.get('DATABASE_URL'));
  await db.connect();

  print("[DB] Conexão OK!");

  final result = await db.query("SELECT NOW() as server_time;");
  print("[DB] Resposta:");
  print(result);

  print("=== TESTE OK ===");
}
