import 'package:sympllizy_back/core/config/environment.dart';

import '../env/env.dart';

class AppConfig {
  static late final Environment environment;
  static late final bool isDebug;
  static late final bool enableQueryLogs;
  static late final String databaseUrl;

  static void load() {
    environment = Environment.fromString(Env.get('APP_ENV', fallback: 'dev'));

    isDebug = environment == Environment.dev;
    enableQueryLogs = environment != Environment.prod;

    databaseUrl = Env.get('DATABASE_URL');

    print('[CONFIG] Environment: $environment');
    print('[CONFIG] Debug: $isDebug');
  }

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;
}
