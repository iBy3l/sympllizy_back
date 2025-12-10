import 'dart:io';

class Env {
  static final Map<String, String> _cache = {};

  static void load({String file = '.env'}) {
    final f = File(file);

    if (!f.existsSync()) {
      throw Exception("Arquivo .env não encontrado em: ${f.path}");
    }

    final lines = f.readAsLinesSync();

    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      final index = line.indexOf('=');
      if (index == -1) continue;

      final key = line.substring(0, index).trim();
      var value = line.substring(index + 1).trim();

      // remove aspas se existirem
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      _cache[key] = value;
    }

    print("[ENV] Carregado: ${_cache.length} variáveis");
  }

  static String get(String key, {String? fallback}) {
    if (_cache.containsKey(key)) return _cache[key]!;

    if (fallback != null) return fallback;

    throw Exception("ENV $key não definido");
  }
}
